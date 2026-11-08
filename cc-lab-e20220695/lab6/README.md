# Cloud Lab 6 Submission — API Gateway and DynamoDB

**Course:** ITC-I5GIC-CC (Cloud Computing)  
**Region:** `us-east-1` (US East N. Virginia)

- **Student name:** CHHEANG HOKLENG  
- **Student ID:** e20220695  
- **Learner Lab user name:** CHHEANG_HOKLENG  
- **Date completed:** 2026-11-09

## What this lab demonstrates

**FruitsAPI** on API Gateway integrates **directly** with DynamoDB table **Fruits** (no Lambda).  
**POST /fruit** adds items; **GET /fruit/{name}** reads one fruit when query parameter **color** is supplied.

---

## 1. DynamoDB table

![Fruits table](images/01-dynamodb-table.png)

Table **Fruits** uses composite primary key **Name** (partition) and **Color** (sort), on-demand capacity, status **Active**.  
No `Flavor` column is defined on the table schema; that attribute is added per item when data is written.

## 2. Table items

![Items in the Fruits table](images/02-dynamodb-items.png)

**Explore table items** shows four rows after seed data and **add_fruit.py**: Apple (Red and Green), Lemon, and **Grapes**.  
Each item has **Name**, **Color**, and **Flavor**, matching the keys used by **GetItem** and **PutItem**.

## 3. REST API resources

![API resources and methods](images/03-api-resources.png)

**FruitsAPI** resources: **POST** on `/fruit` and **GET** on `/fruit/{name}` with path parameter **name**.  
Both methods use **AWS service** integrations to DynamoDB (no Lambda in this lab).

## 4. GET mapping template

![GET mapping template](images/04-get-mapping-template.png)

**Integration request** for GET builds a **GetItem** JSON body: **TableName** `Fruits` and **Key** from **`$input.params('name')`** and **`$input.params('color')`**.  
The client calls HTTP GET, but API Gateway forwards **POST** to the DynamoDB **GetItem** action with this template.

## 5. POST /fruit

![POST request](images/05-post-request.png)

In **CloudShell**, **`python3 add_fruit.py`** sends JSON **`Grapes` / Green / Sour** to **POST /fruit**; the first response is often **`{}`** (successful **PutItem**).  
The script then **GET**s the same fruit and prints the item JSON returned from the API.

## 6. GET /fruit/{name}

![GET request](images/06-get-request.png)

**`python3 get_fruit.py`** calls **GET /fruit/Apple?color=Red** against stage **v1**.  
The printed **Item** shows **Apple**, **Red**, and **Sweet** in DynamoDB attribute format.

## 7. Stage and Invoke URL

![Stage v1](images/07-stage.png)

Stage **v1** is deployed for **FruitsAPI**; the **Invoke URL** is the base for **`get_fruit.py`** and **`add_fruit.py`**.  
After API changes, you must **Deploy API** to **v1** again before the URL serves the latest configuration.

## Scripts

- [populate_table.py](populate_table.py)
- [get_fruit.py](get_fruit.py)
- [add_fruit.py](add_fruit.py)

**Invoke URL in scripts:** `https://5cwwbnwbhc.execute-api.us-east-1.amazonaws.com/v1`

---

## Questions

1. The primary key is **composite**: partition key **`Name`** and sort key **`Color`**. Two items can share the same `Name` when **`Color`** differs, so `Apple / Red` and `Apple / Green` are distinct items.
2. **API Gateway’s AWS service integration** for DynamoDB calls the **DynamoDB control plane API**, which uses **HTTP POST** for actions such as **`GetItem`**, even though the client called **HTTP GET** on the REST API. The REST method is GET; the integration forwards a POST to DynamoDB with the mapped JSON body.
3. A **mapping template** converts the incoming API request into the JSON shape DynamoDB expects. On **GET**, the template sets **`TableName`** to `Fruits` and **`Key.Name.S`** from **`$input.params('name')`** (path) and **`Key.Color.S`** from **`$input.params('color')`** (query string).
4. Without **`color`**, the required query parameter is missing. API Gateway returns a **4xx** client error (for example **400 Bad Request**) and DynamoDB **`GetItem`** is not called with a complete key.
5. **Advantage:** no servers or Lambda to manage; simple CRUD-style integration. **Limit:** limited transformation logic, harder debugging, and tight coupling to DynamoDB compared with Lambda or a full application backend.

## Problems and how I solved them (optional)

- In CloudShell, **`pip3 install requests`** (without `--user`) when the virtualenv rejected **`--user`**.

## Clean up

- [ ] `FruitsAPI` deleted.
- [ ] `Fruits` table deleted.
