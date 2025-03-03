resource "oci_containerengine_addon" "fk_oke_addon" {
    for_each = local.fk_oke_addon_map  
    addon_name = each.key
    cluster_id = oci_containerengine_cluster.fk_oke_cluster.id

    dynamic "configurations" {
        for_each = each.value.configurations
        content {
           key = configurations.key
           value = configurations.value.config_value
        }
   }

    remove_addon_resources_on_delete = true 
    version = each.value.addon_version
}

resource "oci_containerengine_addon" "fk_oke_autoscaler_addon" {
    count = var.virtual_node_pool ? 0 : var.autoscaler_enabled ? 1 : 0 
    addon_name = "ClusterAutoscaler"
    cluster_id = oci_containerengine_cluster.fk_oke_cluster.id

    configurations {
      key = "nodes"
      value = join("", [var.autoscaler_min_number_of_nodes,":",var.autoscaler_max_number_of_nodes,":",oci_containerengine_node_pool.fk_oke_autoscaler_node_pool[0].id],
[var.autoscaler_min_number_of_nodes,":",var.autoscaler_max_number_of_nodes,":",oci_containerengine_node_pool.fk_oke_autoscaler_node_pool_1[0].id])
    }

    configurations {
      key = "scaleDownDelayAfterAdd"
      value = var.autoscaler_scale_down_delay_after_add
    }
 
    configurations {
      key = "scaleDownUnneededTime"
      value = var.autoscaler_scale_down_unneeded_time
    }    

    dynamic "configurations" {
     for_each = var.autoscaler_authtype_workload ? [1] : []
       content {
       key = "authType"
       value = "workload"
     }
    }

    configurations {
      // The number of replicas of the add-on deployment.
      key = "numOfReplicas"
      value = 3
    }  

    configurations {
      // Max time to provision nodes 
      key = "maxNodeProvisionTime"
      value = var.autoscaler_maxNodeProvisionTime
    }  

    remove_addon_resources_on_delete = true
}

resource "oci_containerengine_addon" "oke_cert_manager" {
  addon_name                       = "CertManager"
  cluster_id                       = oci_containerengine_cluster.fk_oke_cluster.id
  remove_addon_resources_on_delete = false
 
}

resource "oci_containerengine_addon" "fh_oke_metricserver_addon" {

    
    #Required
    addon_name = "KubernetesMetricsServer"
    cluster_id = oci_containerengine_cluster.fk_oke_cluster.id

     configurations {
      // The number of replicas of the add-on deployment.
      key = "numOfReplicas"
      value = 3
    }  

    remove_addon_resources_on_delete = false
    

    depends_on = [oci_containerengine_addon.oke_cert_manager]

}
