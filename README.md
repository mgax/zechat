## ZeChat

ZeChat is the working name for a chat system that is:

* **Private** Messages should be encrypted end-to-end, readable only by the
  sender and recipient. Communicating should not reveal your identity.

* **Decentralized** No central authority should control the system. Email is a
  good model, anybody can run their own server. Unlike email, it should be
  possible to seamlessly migrate an identity to a different server.

* **Easy to get started** A web browser should be enough. For total privacy and
  security, you can install the application locally.


### Why not simply use $PROJECT?

There are several existing solutions in this space, and they provide good
inspiration, but each suffer from drawbacks:

* **Threema** It's actually a strong inspiration for ZeChat, but Threema is
  closed source and centralized.

* **Tox** Needs to be installed, has a big feature set and complex network
  protocol.

* **Cryptocat** Centralized (as far as I can tell), and piggy-backs on Jabber,
  which forces some technical trade-offs.

* **Encrypted email** Not really anonymous (the metadata is usually in plain
  text) and your identity is tied to a particular server.


## Architecture

Each participant has an **identity**, which is a public-private RSA key pair.
The keys are used to sign and encrypt messages.

Messages are relayed via **nodes**. They function much as email servers. An
identity will list one or more nodes where inbound messages are to be
delivered. A client will then connect to the node(s) and collect messages, both
in real time, and messages received while it was offline. Nodes can only see
the message recipient; the rest of the message is encrypted and only the
recipient can decrypt it.

### Minimal centralization
Adam Ierymenko wrote a good [article on decentralization](decentralization). He
makes a convincnig argument that full decentralization is impractical, maybe
even impossible. ZeChat makes a choice to rely on a federation of nodes that
are always online but have minimal knowledge of the messages they are relaying.
They do see message recipients and, to some extent, can infer senders, so it's
important for a participant to choose a node they trust, or even run their own.

[decentralization]: http://adamierymenko.com/decentralization-i-want-to-believe/


## The plan
Work is progressing on a minimal functioning implementation of a node and
web-based user interface. When it's ready, it will be possible to run several
nodes, create identities, and exchange messages between them.

### Browser crypto
Admittedly, doing cryptography in the browser can be a [bad idea](jscrypto),
but most of the risks are mitigated by loading the page via HTTPS. You do have
to trust the server, but it's no worse than using Facebook or Google messaging.
Any person or organization can run a node, and serve an instance of the
web-based client, and perhaps decide on a privacy-friendly data retention
policy.

Developing a web-based GUI is also not wasted effort, the code cab be reused to
build a mobile or desktop application, which will swap out the JavaScript-based
cryptography code with a native implementation.

[jscrypto]: http://matasano.com/articles/javascript-cryptography/


## Installation
Clone the project:

```bash
git clone https://github.com/mgax/zechat.git
```

Install dependencies:

```bash
pip install -r requirements.txt
pip install psycopg2  # assuming the database is postgresql
```

Write a configuration file (name it `seettings.py` in the project root):

```python
SQLALCHEMY_DATABASE_URI = 'postgresql:///zechat'
```

Create database and run migrations:

```bash
createdb zechat
./manage.py db upgrade head
```

Run the server:

```bash
uwsgi --module zechat.uwsgi --gevent 100 --http :5000 --http-websockets
```

## Development
Install development dependencies:

```bash
pip install -r requirements-dev.txt
```

Run Python test suite:

```bash
py.test
```

Run browser test suite: set `TESTING_SERVER=True` in your `settings.py` file,
then open http://localhost:5000/_test.
