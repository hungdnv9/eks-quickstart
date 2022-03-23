FROM python:3.9-alpine
WORKDIR /app
COPY ./requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt
COPY app ./
EXPOSE 5000
ENTRYPOINT [ "python" ]
CMD ["app.py" ]
