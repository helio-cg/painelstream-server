{{DOMAIN}} {

    handle_path / {
        root * {{ROOT_PATH}}
        file_server
    }

    @admin path /admin* /status.xsl
    respond @admin 403

    reverse_proxy / 127.0.0.1:8000 {
        header_up X-Forwarded-For {remote_host}
    }
}