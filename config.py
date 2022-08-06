from os import environ

class Config:
    """Base config."""

    SECRET_KEY = environ.get('SECRET_KEY')
    STATIC_FOLDER = 'public/'
    TEMPLATES_FOLDER = 'public/html/'


class Production(Config):

    DEBUG = False
    TESTING = False
    FLASK_ENV = 'production'
    DATABASE_URI = environ.get('DATABASE_URI')


class Development(Config):

    DEBUG = True
    TESTING = True
    FLASK_ENV = 'development'
    DATABASE_URI = environ.get('DATABASE_URI')