from lambda_to_s3_nopandas import lambda_handler

basic = {
    "body": """{
        "first_name": "ian",
        "last_name": "myjer",
        "zip_code": "20010"
    }"""
}
no_fields = {
    "body": """{
        "ian": "myjer"
    }"""
}
empty = {"body": '{}'}

if __name__ == "__main__":
    print(lambda_handler(basic))
    assert lambda_handler(basic)["statusCode"] == 400 # can't write to S3 bucket
    assert lambda_handler(empty)["statusCode"] == 400 # no data passed
    assert lambda_handler(no_fields)["statusCode"] == 400 # no required fields
