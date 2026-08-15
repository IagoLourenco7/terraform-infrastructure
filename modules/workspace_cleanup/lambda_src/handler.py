"""
Lambda: workspace_cleanup
Roda diariamente. Verifica último acesso de cada workspace do Athena
(via tag last-accessed na pasta) e arquiva/deleta conforme inatividade.
"""
import os
import json
import boto3
from datetime import datetime, timezone

s3 = boto3.client("s3")

BUCKET = os.environ["WORKSPACE_BUCKET"]
DAYS_BEFORE_ARCHIVE = int(os.environ.get("DAYS_BEFORE_ARCHIVE", "90"))
DAYS_BEFORE_DELETE = int(os.environ.get("DAYS_BEFORE_DELETE", "180"))


def lambda_handler(event, context):
    archived, deleted = [], []

    paginator = s3.get_paginator("list_objects_v2")
    prefixes = set()
    for page in paginator.paginate(Bucket=BUCKET, Delimiter="/"):
        for p in page.get("CommonPrefixes", []):
            prefixes.add(p["Prefix"])

    for prefix in prefixes:
        last_modified = _get_last_modified(prefix)
        if last_modified is None:
            continue

        days_inactive = (datetime.now(timezone.utc) - last_modified).days

        if days_inactive > DAYS_BEFORE_DELETE:
            _delete_prefix(prefix)
            deleted.append({"workspace": prefix, "days_inactive": days_inactive})
        elif days_inactive > DAYS_BEFORE_ARCHIVE:
            _tag_as_archived(prefix)
            archived.append({"workspace": prefix, "days_inactive": days_inactive})

    _write_report(archived, deleted)

    return {
        "statusCode": 200,
        "body": json.dumps({"archived": len(archived), "deleted": len(deleted)}),
    }


def _get_last_modified(prefix):
    resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix)
    contents = resp.get("Contents", [])
    if not contents:
        return None
    return max(obj["LastModified"] for obj in contents)


def _tag_as_archived(prefix):
    s3.put_object(
        Bucket=BUCKET,
        Key=f"{prefix}.metadata/archived-{datetime.now(timezone.utc).date()}.json",
        Body=json.dumps({"status": "archived", "archived_at": datetime.now(timezone.utc).isoformat()}),
    )


def _delete_prefix(prefix):
    resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix)
    objects = [{"Key": o["Key"]} for o in resp.get("Contents", [])]
    if objects:
        s3.delete_objects(Bucket=BUCKET, Delete={"Objects": objects})


def _write_report(archived, deleted):
    report = {
        "date": datetime.now(timezone.utc).date().isoformat(),
        "archived_workspaces": archived,
        "deleted_workspaces": deleted,
    }
    s3.put_object(
        Bucket=BUCKET,
        Key=f"workspace-cleanup-reports/{datetime.now(timezone.utc).date()}.json",
        Body=json.dumps(report, default=str),
    )
