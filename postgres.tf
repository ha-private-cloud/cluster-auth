# Plain postgres:16
resource "random_password" "postgres" {
  length  = 24
  special = false
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.cluster_auth.metadata[0].name
  }

  data = {
    POSTGRES_USER     = "authentik"
    POSTGRES_PASSWORD = random_password.postgres.result
    POSTGRES_DB       = "authentik"
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.cluster_auth.metadata[0].name
  }

  spec {
    cluster_ip = "None" # headless, for stable StatefulSet pod DNS
    selector = {
      app = "postgres"
    }
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_stateful_set_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.cluster_auth.metadata[0].name
  }

  spec {
    service_name = kubernetes_service.postgres.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        # Makes the NFS subdirectory writable by postgres's uid/gid (999);
        # csi-driver-nfs's fsGroupPolicy=File honors this without custom mountPermissions.
        security_context {
          fs_group = 999
        }

        container {
          name  = "postgres"
          image = var.postgres_image

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.postgres.metadata[0].name
            }
          }

          port {
            container_port = 5432
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
            # Avoids NFS placing its own directory entries directly in PGDATA, which Postgres is picky about.
            sub_path = "pgdata"
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", "authentik"]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }

      }
    }

    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "nfs-csi"
        resources {
          requests = {
            storage = var.postgres_storage_size
          }
        }
      }
    }
  }
}
