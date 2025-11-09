# This file defines the input variables for our project.

variable "aws_region" {
  description = "The AWS region to deploy all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "A unique name for the project to prefix resources."
  type        = string
  default     = "iotAccessControl"
}