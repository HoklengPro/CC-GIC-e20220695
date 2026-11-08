import json
import requests

url = 'https://5cwwbnwbhc.execute-api.us-east-1.amazonaws.com/v1'
new_fruit = {
    'name': 'Grapes',
    'color': 'Green',
    'flavor': 'Sour',
}
final_url = f'{url}/fruit'

response = requests.post(final_url, json=new_fruit).json()
print(json.dumps(response, indent=4))

final_url = f'{url}/fruit/Grapes'
response = requests.get(final_url, params={'color': 'Green'}).json()
print(json.dumps(response, indent=4))
