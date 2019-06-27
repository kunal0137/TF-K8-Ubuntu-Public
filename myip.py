import requests
from terraform_external_data import terraform_external_data

@terraform_external_data
def myip(query):
	return {'IP':str(requests.get("http://wtfismyip.com/json").json()['YourFuckingIPAddress'])}

if __name__ == '__main__':
    myip()
