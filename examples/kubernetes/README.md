# UniFi Controller on Kubernetes

On Kubernetes we run MongoDB as a ReplicaSet (just for fun).

The MongoDB database goes through a couple of stages before it is ready:

## Init Database

An init container sets the admin credentials and creates a user for the UniFi Controller.

## Init ReplicaSet

Due to limitations of MongoDB, we use a Kubernetes job to initialize the ReplicaSet. This cannot be done automatically at database init because MongoDB init is run with localhost access only, so we cannot see the other nodes in the ReplicaSet.
