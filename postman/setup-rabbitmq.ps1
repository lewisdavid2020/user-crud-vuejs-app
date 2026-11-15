# Prepara RabbitMQ local para las escrituras de user-service.
# Crea el contenedor si no existe, lo inicia y declara el exchange, la cola y el binding.
$ErrorActionPreference = 'Stop'

$container = 'user-service-rabbitmq'
$image = 'rabbitmq:3.13-management'
$exchange = 'domain.events'
$queue = 'domain.events.postman'
$credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('guest:guest'))
$headers = @{ Authorization = "Basic $credentials" }
$managementUrl = 'http://localhost:15672/api'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw 'Docker no está instalado o no está en el PATH.'
}

$existing = docker ps -a --filter "name=^/$container$" --format '{{.Names}}'
if (-not $existing) {
  Write-Host "Creando contenedor $container..."
  docker run -d --name $container -p 5672:5672 -p 15672:15672 $image | Out-Null
} else {
  $running = docker inspect -f '{{.State.Running}}' $container
  if ($running -ne 'true') {
    Write-Host "Iniciando contenedor $container..."
    docker start $container | Out-Null
  }
}

Write-Host 'Esperando a RabbitMQ...'
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
  try {
    $response = Invoke-WebRequest -Uri "$managementUrl/overview" -Headers $headers -TimeoutSec 3 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
      $ready = $true
      break
    }
  } catch {
    Start-Sleep -Seconds 2
  }
}

if (-not $ready) {
  throw "RabbitMQ no respondió en $managementUrl. Revisa: docker logs $container"
}

$exchangeBody = '{"type":"topic","auto_delete":false,"durable":true,"internal":false,"arguments":{}}'
$queueBody = '{"auto_delete":false,"durable":true,"arguments":{}}'
$bindingBody = '{"routing_key":"#","arguments":{}}'

Invoke-RestMethod -Method Put -Uri "$managementUrl/exchanges/%2F/$exchange" -Headers $headers -ContentType 'application/json' -Body $exchangeBody | Out-Null
Invoke-RestMethod -Method Put -Uri "$managementUrl/queues/%2F/$queue" -Headers $headers -ContentType 'application/json' -Body $queueBody | Out-Null
Invoke-RestMethod -Method Post -Uri "$managementUrl/bindings/%2F/e/$exchange/q/$queue" -Headers $headers -ContentType 'application/json' -Body $bindingBody | Out-Null

Write-Host "RabbitMQ listo: exchange=$exchange cola=$queue binding=#"
Write-Host 'Panel de administración: http://localhost:15672 (guest / guest)'
