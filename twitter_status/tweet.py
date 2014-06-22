#!/usr/bin/env python
import sys
from twython import Twython

#import access tokens from auth_tokens.py
from auth_tokens import *

api = Twython(CONSUMER_KEY,CONSUMER_SECRET,ACCESS_KEY,ACCESS_SECRET) 

api.update_status(status=sys.argv[1][:140])
