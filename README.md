# **Eloquent**: A unified semantic data modeling language designed for the age of LLMs. 

*Use natural language to describe your data in a markdown-like format and generate various products from it.*

Anyone who has run an enterprise data organization at scale understands how difficult it is to keep metadata updated and synced with all the various databases, data products, semantic layers, monitoring, catalogs, external BI tools and now RAG-based large language models. If only there was a single data modeling language that could generated everything that would need to update as code. 

**Author's Note**: Eloquent grew from my experience with very large enterprise data architectures and I've been evolving it based on real experiences with clients. If you choose to use Eloquent, any experience you can [share](#contact) about using the language, how it feels, where it behaves unexpectedly or where it appears redundant is much appreciated. Contributions of additional output products are welcome, see [Contributing](#contributing).

---

# Products

- [**Knowledge Graph**](#the-knowledge-graph): A graph of interrelated concepts based on your model, forming the source of truth for the entire framework.
- [**Physical Target Database Schema**](#the-physical-layer): A detailed view of how the model would look in a database, showing which parts of the graph are available to query.
- [**Write Queries**](#write-queries): Ask a question to an LLM and get back a sql query that can answer it
- [**SQL Test Scripts**](#sql-test-scripts): Automatically generated SQL tests to validate your data model’s integrity.
- [**RAG-Compatible Versions**](#rag-compliant-models): Create representations of your model that are ready for vector databases and LLMs.
- [**Natural Language to SQL Pairs**](#natural-language-to-sql): Generate question-answer pairs in natural language that can be transformed into SQL queries.
- [**Data Catalog**](#data-catalog): A fully generated PDF or HTML catalog of your data model, including context from the model’s descriptions.
- [**Expanded Logical Views**](#expanded-logical-views): Logical entities extracted from the physical schema to enhance analysis.
- [**Observability Scripts**](#observability-scripts): Scripts to monitor and ensure the health of the data model over time.
- [**Aggregations and Metrics Matrix**](#aggregations-and-metrics-matrix): Standardized transformations and aggregations for reporting and analytics.
- [**ERD Diagrams**](#erd-diagrams): Visualizations of the data model showing relationships between entities.
- **DBT-Compatible Data Models**: Generate models that integrate seamlessly with DBT for transformation workflows.
- **External Data Governance**: Sync the model with external tools like Microsoft Purview or Collibra
- **VSCode Extension**: Syntax highlighting and linting for VSCode

---

## 💡 Usage

This is an Eloquent data model:

```markdown
**Person**: A person or organization
- Person has a Name
- Customer is a Person with at least one Order

**Customer**: A person or organization that buys products
- Customer has a Zipcode like '10000'

**Order**: A record of a customer's purchase of one or more products
- Order has a Customer
- Order must have an Order Date in the past

**Order Date**: The date the order was placed
- Order Date is a Date
```

A markdown-like syntax represents the metadata in a semi-structured text format. AI code editors pick up on this pattern very easily which makes modelling much more pleasent. From it we can start to manifest the model in different ways.

### The Knowledge Graph

The core list of the concepts and their relationships. This is the source of truth for the model and is used to generate all the other outputs. Note that the graph can surface derived attributes that were not explictly part of the model, such as the customer zipcode and name for an order.

```bash
> eloquent describe graph
Person
- Name
Customer
- Zipcode
Order
- Order Date
- Customer Zipcode
- Customer Person Name
Customers make Orders
A Person with at least one Order is a Customer
```

### The Physical Layer

What the knowledge graph would look like if it was backed by a database. You can determine what data is available by comparing these definitions against the available tables.

```bash
> eloquent describe physical
physical_person
- person_id: String
- person_name: String
physical_customer
- customer_id: String
- customer_zipcode: String
physical_order
- order_id: String
- order_date: Date
- customer_id: String
```

### The Physical Schema

CREATE TABLE statements that can be used to create the physical tables in a particular database technology. These are generally populated by ETL tools but may also be replaced with views to other tables.

```bash
> eloquent create physical mysql
CREATE TABLE physical_person (
  person_id VARCHAR(255) PRIMARY KEY,
  person_name VARCHAR(255)
);

CREATE TABLE physical_customer (
  customer_id VARCHAR(255) PRIMARY KEY,
  customer_zipcode VARCHAR(255)
  FOREIGN KEY (customer_id) REFERENCES physical_person(person_id)
);

CREATE TABLE physical_order (
  order_id VARCHAR(255) PRIMARY KEY,
  order_date DATE,
  customer_id VARCHAR(255),
  FOREIGN KEY (customer_id) REFERENCES physical_customer(customer_id)
);
```

### Expanded Logical Views

Generate views that create a layer of logical entities that are more useful for analysis. Every entity becomes its own mini-data warehouse. 

```bash
> eloquent create logical mysql
CREATE VIEW logical_person AS
SELECT
  person_id,
  person_name
FROM physical_person;

CREATE VIEW logical_customer AS
SELECT
  customer_id,
  customer_zipcode,
  person_id,
  person_name
FROM physical_customer;

CREATE VIEW logical_order AS
SELECT
  order_id,
  order_date,
  customer_id,
  customer_zipcode,
  person_id,
  person_name
FROM physical_order
JOIN physical_customer ON order.customer_id = customer.customer_id
JOIN physical_person ON customer.customer_id = person.person_id;
```


### Write Queries

Ask a natural language question and use the data model to generate sql code that will answer the question.

```bash
> eloquent ask mysql What is the total number of orders placed by customers in zipcode '10000'?
SELECT COUNT(*) FROM logical_order WHERE customer_zipcode = '10000';
```

### SQL Test Scripts

Most distributed data technologies do not enforce primary or foreign key relationships so these sql tests are neccessary to enforce the constraints of the data model. Each select statement will return no rows or a single row with value 0 if the model is correct and a non-zero number of rows of single row value > 1 if there are errors. 

```bash
> eloquent test logical mysql
/* Assert at least one row exists in the logical Order view */ SELECT CASE WHEN COUNT(*) > 0 THEN 0 ELSE 1 END FROM logical_order;
/* Assert no null values for the primary key (order_id) in the logical Order view */ SELECT COUNT(*) FROM logical_order WHERE order_id IS NULL;
/* Assert no duplicate values for the primary key (order_id) in the logical Order view */ SELECT COUNT(*) FROM logical_order GROUP BY order_id HAVING COUNT(*) > 1;
/* Assert no null values for the required column (order_date) in the logical Order view */ SELECT COUNT(*) FROM logical_order WHERE order_date IS NULL;
/* Assert no future order_date values in the logical Order view */ SELECT COUNT(*) FROM logical_order WHERE order_date > CURRENT_DATE;
...
```

### Observability Scripts

Monitor the data model and ensure that the data is being updated correctly. They can be run on a schedule to ensure that the data is being monitored. Note that these can have cost implications if run too frequently.

```bash
> eloquent observe physical pysparkwhylogs
from logging import getLogger
import json
import datetime
logger = getLogger("eloquent")
import whylogs as why
from whylogs.api.pyspark.experimental import collect_dataset_profile_view
for table in ['physical_person', 'physical_customer', 'physical_order', 'logical_person', 'logical_customer', 'logical_order']:
    df = spark.read.table(table)
    profile = collect_dataset_profile_view(input_df=df)
    profile = {"name" : table, "profiled_at" : datetime.datetime.now().isoformat(), "profile" : profile.to_pandas().to_dict(index='records')}
    logger.info(json.dumps(profile))
```

### RAG-Compliant Models

Expand on the model's explicit definitions to include additional context that is useful for a large language model to understand the data. This document would be chunked and stored in a vector database for the LLM to use.

```bash
> eloquent describe rag
**Person**: A person or organization
- Person has a Name
**Customer**: A person or organization that buys products
- Customer is a Person with at least one Order
- Customer has a Zipcode like '10000'
**Order**: A record of a customer's purchase of one or more products
- Order has a Customer
- Order must have an Order Date in the past
- Order has a Customer Zipcode
- Order has a Customer Person Name
```

### Aggregations and Metrics Matrix

Apply a standard set of transformations, aggregations and metrics to the logical views to drive reporting and analytics. Future versions of Eloquent will include a way to specify non-default versions of these.

```bash
> eloquent create matrix mysql
CREATE VIEW order_count_by_customer AS SELECT customer_id, COUNT(*) AS order_count FROM logical_order GROUP BY customer_id;
CREATE VIEW order_count_by_customer_zipcode AS SELECT customer_zipcode, COUNT(*) AS order_count FROM logical_order GROUP BY customer_zipcode;
CREATE VIEW order_count_by_customer_zipcode_and_order_date AS SELECT customer_zipcode, order_date, COUNT(*) AS order_count FROM logical_order GROUP BY customer_zipcode, order_date;
CREATE VIEW order_count_by_customer_zipcode_and_order_date_week AS SELECT customer_zipcode, order_date_week, COUNT(*) AS order_count FROM logical_order GROUP BY customer_zipcode, order_date_week;
CREATE VIEW order_count_by_customer_zipcode_and_order_date_month AS SELECT customer_zipcode, order_date_month, COUNT(*) AS order_count FROM logical_order GROUP BY customer_zipcode, order_date_month;
...
```

### Natural Language to SQL

Generate a set of natural language to SQL question/answer pairs that can be used to query the data model or train a chatbot or other natural language interface to the data.

```bash
> eloquent nlp mysql 5
What is the name of the person with person_id '12345'? => SELECT person_name FROM logical_person WHERE person_id = '12345';
How many orders have been placed by the customer with customer_id '12345'? => SELECT COUNT(*) FROM logical_order WHERE customer_id = '12345';
What is the total number of orders placed by customers in zipcode '10000'? => SELECT COUNT(*) FROM logical_order WHERE customer_zipcode = '10000';
When was the most recent order placed by the customer with customer_id '12345'? => SELECT MAX(order_date) FROM logical_order WHERE customer_id = '12345';
When was the first ever order placed? => SELECT MIN(order_date) FROM logical_order;
```

### ERD Diagrams

Generate a visual representation of the model that can be used to understand the relationships between the entities.

### Data Catalog

Generate a data catalog that contains all the information in the model plus additional context from the descriptions as either a PDF or a collection of HTML pages. This can be used to understand the data model and how it can be navigated and attractively printed.

---

## 🥞 Testing

To run the test suite:

1. Clone the repository:

    ```bash
    git clone https://github.com/eloquentanalytics/pyeloquent.git
    ```

2. Install development dependencies:

    ```bash
    pip install -r requirements.txt
    ```

3. Run the tests:

    ```bash
    pytest
    ```

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch for your feature or bugfix:

    ```bash
    git checkout -b feature-name
    ```

3. Make your changes and commit them with a clear message.
4. Submit a pull request.

Please see the `CONTRIBUTING.md` file for detailed guidelines.

---

## License

**Eloquent** is licensed under the Business Source License 1.1 (BSL 1.1).

Certain usage restrictions apply. For details, see the `LICENSE` file.

---

## Changelog

See the `CHANGELOG.md` file for details on new features, bug fixes, and updates.

---

## Contact

For questions, feedback, or support, feel free to reach out:

- **GitHub Issues**: Submit an issue
- **Email**: philip@eloquentanalytics.com
- **Website**: https://www.eloquentanalytics.com





