FROM continuumio/miniconda3

# update base environment
COPY environment.yml environment.yml
RUN /opt/conda/bin/conda env update --file environment.yml

# TODO: handle aws configuration

# add user for security
RUN useradd -ms /bin/bash fastapi
USER fastapi
WORKDIR /home/fastapi

# deployment stuff
COPY --chown=fastapi:fastapi api.py /home/fastapi/api.py
ENV data_bucket_name 'elasticbeanstalk-us-east-2-433547099107'
EXPOSE 8000

CMD ["uvicorn","api:app","--host","0.0.0.0","--port","8000"]
