/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

data "aws_region" "current" {}

locals {
  image_url = var.public_docker_repo ? var.aws_for_fluent_bit_image_repo_name : "${var.private_container_repo_url}/${var.aws_for_fluent_bit_image_repo_name}"
}

resource "aws_cloudwatch_log_group" "eks_worker_logs" {
  name              = "/aws/eks/${var.cluster_id}/fluentbit-cloudwatch-logs"
  retention_in_days = var.ekslog_retention_in_days
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
}

resource "helm_release" "aws-for-fluent-bit" {
  name       = var.aws_for_fluent_bit_helm_chart_name
  repository = var.aws_for_fluent_bit_helm_chart_url
  chart      = var.aws_for_fluent_bit_helm_chart_name
  version    = var.aws_for_fluent_bit_helm_chart_version
  namespace  = kubernetes_namespace.logging.id
  timeout    = "1200"
  values = [templatefile("${path.module}/templates/aws-for-fluent-bit-values.yaml", {
    image              = local.image_url
    tag                = var.aws_for_fluent_bit_image_tag
    cw_worker_loggroup = aws_cloudwatch_log_group.eks_worker_logs.name
    region             = data.aws_region.current.name
  })]
}

