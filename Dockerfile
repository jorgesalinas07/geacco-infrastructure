FROM python:3.8-slim-buster

RUN mkdir -p /home/app
ENV HOME=/home/app
# create the app user
RUN addgroup --system app && adduser --system --group app

# create the appropriate directories
ENV APP_HOME=/app
RUN mkdir $APP_HOME
RUN mkdir $APP_HOME/static
WORKDIR $APP_HOME

# install dependencies
RUN apt update
RUN apt install -y build-essential libpcre3 libpcre3-dev vim python-dev libpq-dev

COPY requirements.txt requirements.txt
RUN pip --disable-pip-version-check install -r requirements.txt

# copy project
COPY . $APP_HOME

# chown all the files to the app user
RUN chown -R app:app $APP_HOME

# Give permissions to the directory
USER root
RUN mkdir /usr/local/lib/python3.8/site-packages/cities_light/data
RUN chmod -R 777 /usr/local/lib/python3.8/site-packages/cities_light/data

# change to the app user
USER app

# RUN python manage.py collectstatic --noinput
RUN chown -R app:app $APP_HOME

# Expose the port your Django app will run on
EXPOSE 8002
