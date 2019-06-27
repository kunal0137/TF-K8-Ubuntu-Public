import json
from jinja2 import Template
from terraform_external_data import terraform_external_data

@terraform_external_data
def genslave(query):
	#json_file = open(query['fileName'])
	#slave_data =json.load(json_file)
	slave_data = json.loads(query['json_data'])
	t = Template('''{% for ip in data -%}
{{ip}}
{% endfor %} ''')
	output = t.render(data=slave_data)
	text_file = open("slave_ip.txt", "w")
	text_file.write(output)
	text_file.close()
    	return {'text_file':str(text_file)}

	#return text_file

if __name__ == '__main__':
    genslave()
