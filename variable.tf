variable "cidr_block" {
  type = string
  description = "cidr for virtual network"
  default = "10.20.0.0/16"
}

variable "organization" {
    type = string
    description = "name of the organization"
    default = "1ch"
}

variable "subnet_count" {
    type = number
    description = "Enter the count of the subnet needed in the virtual network"
    default = 1
}

variable "client_id" {
    type = string
    description = "Enter the client id"
    default = "80400782-02ec-4f98-b1e2-f0c4dd8067a8"
}

variable "client_secret" {
    type = string
    description = "Enter the secret"
    default = "nDJ8Q~w4PLzVtmcYNFWQ9nnFSL1fRcsksGSOBb6t"
}

variable "tenant_id" {  
    type = string
    description = "Enter the tenant id" 
    default = "d6a66152-b819-4636-b222-ca6fd2fad656"
}

variable "subscription_id" {
    type = string
    description = "Enter the subscription id"
    default = "2153dcaa-22b1-42d6-8ce6-f576f5ecd16d"
}