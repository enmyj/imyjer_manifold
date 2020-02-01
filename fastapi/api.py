from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict

import boto3
import datetime
import os
import json

class Person(BaseModel):
    first_name: str = None
    middle_name: str = None
    last_name: str = None
    zip_code: str = None

_req_fields = [
    'first_name',
    'middle_name',
    'last_name',
    'zip_code'
]


app = FastAPI()


@app.post("/v1/", status_code=200)
def parse_person(data: Dict[str, str]):
    """ parse a person's information out of a json response
    """
    # check for blank event
    if not data:
        raise HTTPException(status_code=400, detail="No data passed")

    # add field to dict if not exists
    # increment missing field counter
    cnt = 0
    for field in _req_fields:
        if not data.setdefault(field, None):
            cnt += 1

    # ensure at least one required field was passed
    if cnt == len(_req_fields):
        raise HTTPException(
            status_code=400,
            detail=f"None of the required fields: {_req_fields} were passed"
        )

    # output data to S3 as JSON
    ts = datetime.datetime.utcnow()
    data['timestamp'] = str(ts)

    s3 = boto3.resource("s3")
    try:
        s3.Object(
            os.getenv('data_bucket_name'),
            f'data/{ts.date()}/data_{ts}.json'
        ).put(Body=json.dumps(data))
    except:
        raise HTTPException(status_code=400, detail="Unable to write to S3")

    return 'Success!'
