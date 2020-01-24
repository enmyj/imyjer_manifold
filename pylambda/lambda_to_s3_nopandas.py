import boto3
import json
import datetime
import os


_req_fields = [
    'first_name',
    'middle_name',
    'last_name',
    'zip_code'
]


def lambda_handler(event, context = None) -> dict:
    """ Assumes top-level json, 1 person per http request
    
    Steps:
        parse json body
        ensure at least 1 required field was passed
        write all passed data as json to s3 with day as folder name
    """
    data = event['body']

    # useful type conversion for testing via lambda web interface
    if type(data) == str:
        data = json.loads(data)

    # check for blank event
    if not data:
        return {
            'statusCode': 400,
            'body': (
                f'<p>No data passed in http POST body</p>'
            )
        }

    # add field to dict if not exists
    # increment missing field counter
    cnt = 0
    for field in _req_fields:
        if not data.setdefault(field, None):
            cnt += 1

    # ensure at least one required field was passed
    if cnt == len(_req_fields):
        return {
            'statusCode': 400,
            'body': (
                f'<p>None of the fields: {_req_fields} '
                'were included in json body</p>'
            )
        }

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
        return {
            'statusCode': 400,
            'body': (
                '<p>Unable to write to S3 target</p>'
            )
        }  

    # return success status code
    return {
        'statusCode': 200,
        'body': '<p>Success</p>'
    }
