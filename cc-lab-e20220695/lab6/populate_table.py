import boto3

# Initializing the DynamoDB client
# (credentials come from CloudShell or ~/.aws/credentials, never from this file)
dynamodb = boto3.client('dynamodb', region_name='us-east-1')


def insert_fruit(name, color, flavor):
    dynamodb.put_item(
        TableName='Fruits',
        Item={
            'Name': {'S': name},
            'Color': {'S': color},
            'Flavor': {'S': flavor},
        },
    )


if __name__ == '__main__':
    insert_fruit('Apple', 'Red', 'Sweet')
    insert_fruit('Apple', 'Green', 'Sour')
    insert_fruit('Lemon', 'Yellow', 'Sour')
    print('Table populated successfully.')
