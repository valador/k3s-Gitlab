Разрешаем подключение к кластеру
Admin > Settings > Network > expand "Outbound requests" > check:
* Allow requests to the local network from web hooks and services - иначе не работает добавление кластера по dns имени или ip (localhost все равно не принимает)
* Allow requests to the local network from system hooks
Настроить ранеры