using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Poc.PrivateLink.Functions;

public class HealthCheck
{
    private readonly ILogger<HealthCheck> _logger;

    public HealthCheck(ILogger<HealthCheck> logger)
    {
        _logger = logger;
    }

    [Function("HealthCheck")]
    public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");
        return new OkObjectResult("Function is running.");

    }
}