{{DOMAIN}} {

    handle_path / {
        root * {{ROOT_PATH}}
        file_server
    }

    #@admin path /admin* /status* /server_version.xsl
    #respond @admin 403

    # Redireciona /status*, /admin*, /server_version.xsl para /
    @block path /admin* /status* /server_version.xsl
    rewrite @block /  # vai servir o root
    # ou se quiser redirecionar de fato:
    # redir @block / 302

    reverse_proxy 127.0.0.1:8000 {
        header_up X-Forwarded-For {remote_host}
        flush_interval -1

        transport http {
            keepalive 0
        }
    }
}