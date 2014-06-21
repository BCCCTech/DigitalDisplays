#!/usr/bin/env python

import cmd
import locale
import os
import pprint
import shlex
import sys

from dropbox import client, rest

# Fill in your consumer key and secret below
# You can find these at http://www.dropbox.com/developers/apps
APP_KEY = 'je29wnwyzol79ag'
APP_SECRET = 'j6gtwiq44zhv57o'

class SlideshowImageGetter(cmd.Cmd):
    TOKEN_FILE = "token_store.txt"

    def __init__(self, app_key, app_secret):
        self.app_key = app_key
        self.app_secret = app_secret
        self.current_path = ''

        self.api_client = None
        try:
            token = open(self.TOKEN_FILE).read()
            self.api_client = client.DropboxClient(token)
            print "[loaded access token]"
        except IOError:
            pass # don't worry if it's not there

    def do_list(self):
        """list files in current remote directory"""
        resp = self.api_client.metadata(self.current_path)

        file_list=[]
        if 'contents' in resp:
            for f in resp['contents']:
                name = os.path.basename(f['path'])
                encoding = locale.getdefaultlocale()[1]
                file_list.append(name)
        return file_list

    def do_login(self):
        """log in to a Dropbox account"""
        flow = client.DropboxOAuth2FlowNoRedirect(self.app_key, self.app_secret)
        authorize_url = flow.start()
        sys.stdout.write("1. Go to: " + authorize_url + "\n")
        sys.stdout.write("2. Click \"Allow\" (you might have to log in first).\n")
        sys.stdout.write("3. Copy the authorization code.\n")
        code = raw_input("Enter the authorization code here: ").strip()

        try:
            access_token, user_id = flow.finish(code)
        except rest.ErrorResponse, e:
            self.stdout.write('Error: %s\n' % str(e))
            return

        with open(self.TOKEN_FILE, 'w') as f:
            f.write(access_token)
        self.api_client = client.DropboxClient(access_token)

#    def do_logout(self):
#        """log out of the current Dropbox account"""
#        self.api_client = None
#        os.unlink(self.TOKEN_FILE)
#        self.current_path = ''

    def do_get(self, from_path, to_path):
        """
        Copy file from Dropbox to local file and print out the metadata.

        Examples:
        Dropbox> get file.txt ~/dropbox-file.txt
        """
        to_file = open(os.path.expanduser(to_path), "wb")

        f, metadata = self.api_client.get_file_and_metadata(self.current_path + "/" + from_path)
        #print 'Metadata:', metadata
        to_file.write(f.read())

    def get_slides(self,slide_path="/Photos/slideshow" ):
        if not hasattr(self,'api_client') or self.api_client is None:
            self.do_login()
        
        self.current_path = slide_path
        slides=self.do_list()
        for f in slides:
            print "Downloading ", f, "..."
            self.do_get(f,f) #remote,local
        sys.exit()

def main():
    if APP_KEY == '' or APP_SECRET == '':
        exit("You need to set your APP_KEY and APP_SECRET!")
    getter = SlideshowImageGetter(APP_KEY, APP_SECRET)
    getter.get_slides()

if __name__ == '__main__':
    main()
