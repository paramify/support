# Inheritance - can't live without it
Inheritance allows you to assign responsibility to another system.

## Overview
Many security capabilities can be inherited from other systems. This common if your organization is utilizing a cloud service provider such as AWS, GCP, or Azure among others. In this cases, the cloud service provider is responsible for the security of the cloud, and you are responsible for the security of your data and applications in the cloud. 

## Setting up Inheritance
A Risk Solution can inherit capability by setting the **Origination** field to `Inherited`. When a Risk Solution's origination is `Inherited`, the **Main Component** must be associated with another FedRAMP system. This association can take two forms:
- The Main Component is another FedRAMP System
- The Main Component is a sub-component of another FedRAMP System. The sub-component must specify a "Leveraged Authorization" which is the authorized FedRAMP System. (e.g. The Risk Solution can inherit from AWS EC2, which gets its authorization from the AWS US East/West service)

The details of the inheritance will propagate into appropriate deliverables.
