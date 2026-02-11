# Application Configuration Guide

## Overview

This guide covers all configuration aspects of the LoanProcessing web application, including connection strings, application settings, security, and environment-specific configurations.

## Configuration Files

### Web.config (Main Configuration)

Location: `LoanProcessing.Web\Web.config`

This is the primary configuration file containing:
- Connection strings
- Application settings
- System configuration
- Entity Framework configuration
- Compilation settings

### Web.Debug.config (Development Transformation)

Location: `LoanProcessing.Web\Web.Debug.config`

Applied during Debug builds. Used for:
- Development-specific settings
- Verbose logging
- Detailed error messages

### Web.Release.config (Production Transformation)

Location: `LoanProcessing.Web\Web.Release.config`

Applied during Release builds. Used for:
- Production connection strings
- Optimized settings
- Security hardening

## Connection Strings

### Development (LocalDB)

```xml
<connectionStrings>
  <add name="LoanProcessingConnection" 
       connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=LoanProcessing;Integrated Security=True;Connect Timeout=30;Encrypt=False;TrustServerCertificate=False;ApplicationIntent=ReadWrite;MultiSubnetFailover=False" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

**When to use**: Local development on developer workstations

**Pros**:
- No separate SQL Server installation required
- Included with Visual Studio
- Automatic startup/shutdown

**Cons**:
- Single-user only
- Limited to local machine
- Not suitable for production


### Production (SQL Server - Windows Authentication)

```xml
<connectionStrings>
  <add name="LoanProcessingConnection" 
       connectionString="Server=PROD_SERVER_NAME;Database=LoanProcessing;Trusted_Connection=True;Connect Timeout=30;Encrypt=True;TrustServerCertificate=False;MultipleActiveResultSets=True" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

**When to use**: Production environment with Windows Authentication

**Pros**:
- No passwords in configuration
- Uses Windows security
- Integrated with Active Directory

**Cons**:
- Requires domain environment
- Application pool identity must have database access

**Configuration Steps**:
1. Set IIS Application Pool identity to domain account
2. Grant database permissions to that account
3. Update `PROD_SERVER_NAME` with actual server name

### Production (SQL Server - SQL Authentication)

```xml
<connectionStrings>
  <add name="LoanProcessingConnection" 
       connectionString="Server=PROD_SERVER_NAME;Database=LoanProcessing;User Id=LoanProcessingApp;Password=ENCRYPTED_PASSWORD;Connect Timeout=30;Encrypt=True;TrustServerCertificate=False;MultipleActiveResultSets=True" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

**When to use**: Production without Windows Authentication

**Security Warning**: Never store passwords in plain text!

**Recommended Approach**: Use encrypted configuration sections

```powershell
# Encrypt connection strings section
aspnet_regiis -pef "connectionStrings" "C:\inetpub\wwwroot\LoanProcessing" -prov "RsaProtectedConfigurationProvider"

# Decrypt (if needed)
aspnet_regiis -pdf "connectionStrings" "C:\inetpub\wwwroot\LoanProcessing"
```

### Azure SQL Database

```xml
<connectionStrings>
  <add name="LoanProcessingConnection" 
       connectionString="Server=tcp:SERVERNAME.database.windows.net,1433;Initial Catalog=LoanProcessing;Persist Security Info=False;User ID=USERNAME;Password=PASSWORD;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

**When to use**: Cloud deployment on Azure

**Additional Configuration**:
- Enable Azure AD authentication (recommended)
- Configure firewall rules
- Use Azure Key Vault for secrets

## Application Settings

### Core Settings

```xml
<appSettings>
  <!-- MVC Configuration -->
  <add key="webpages:Version" value="3.0.0.0" />
  <add key="webpages:Enabled" value="false" />
  <add key="ClientValidationEnabled" value="true" />
  <add key="UnobtrusiveJavaScriptEnabled" value="true" />
  
  <!-- Application Name -->
  <add key="ApplicationName" value="Loan Processing System" />
  <add key="ApplicationVersion" value="1.0.0" />
</appSettings>
```

### Business Rules Configuration

```xml
<appSettings>
  <!-- Loan Amount Limits by Type -->
  <add key="MaxLoanAmount_Personal" value="50000" />
  <add key="MaxLoanAmount_Auto" value="75000" />
  <add key="MaxLoanAmount_Mortgage" value="500000" />
  <add key="MaxLoanAmount_Business" value="250000" />
  
  <!-- Loan Term Limits (months) -->
  <add key="MinLoanTerm" value="12" />
  <add key="MaxLoanTerm" value="360" />
  
  <!-- Credit Score Thresholds -->
  <add key="MinCreditScore" value="300" />
  <add key="MaxCreditScore" value="850" />
  <add key="AutoApprovalCreditScore" value="750" />
  <add key="ManualReviewCreditScore" value="650" />
  
  <!-- Risk Assessment -->
  <add key="MaxDebtToIncomeRatio" value="43" />
  <add key="PreferredDebtToIncomeRatio" value="35" />
  <add key="HighRiskThreshold" value="50" />
</appSettings>
```

### Feature Flags

```xml
<appSettings>
  <!-- Enable/Disable Features -->
  <add key="Feature_AutomaticCreditEvaluation" value="true" />
  <add key="Feature_PaymentScheduleGeneration" value="true" />
  <add key="Feature_PortfolioReporting" value="true" />
  <add key="Feature_InterestRateManagement" value="true" />
  
  <!-- Logging -->
  <add key="EnableDetailedLogging" value="false" />
  <add key="LogLevel" value="Warning" />
</appSettings>
```


## System Configuration

### Compilation Settings

```xml
<system.web>
  <compilation debug="false" targetFramework="4.7.2" />
  <httpRuntime targetFramework="4.7.2" maxRequestLength="10240" executionTimeout="300" />
</system.web>
```

**Debug Mode**:
- `debug="true"`: Development (detailed errors, no optimization)
- `debug="false"`: Production (optimized, generic errors)

**Important**: Always set `debug="false"` in production!

### Custom Errors

```xml
<system.web>
  <!-- Development -->
  <customErrors mode="Off" />
  
  <!-- Production -->
  <customErrors mode="On" defaultRedirect="~/Error">
    <error statusCode="404" redirect="~/Error/NotFound" />
    <error statusCode="500" redirect="~/Error/ServerError" />
  </customErrors>
</system.web>
```

**Modes**:
- `Off`: Show detailed errors (development only)
- `On`: Show custom error pages (production)
- `RemoteOnly`: Detailed errors locally, custom errors remotely

### Session State

```xml
<system.web>
  <sessionState mode="InProc" timeout="20" />
</system.web>
```

**Modes**:
- `InProc`: In-process (default, fastest, not scalable)
- `StateServer`: Out-of-process (scalable, requires service)
- `SQLServer`: Database (most reliable, slower)
- `Custom`: Redis or other providers

**For Production Web Farms**:
```xml
<sessionState mode="SQLServer" 
              sqlConnectionString="Server=SESSION_SERVER;Database=ASPState;Integrated Security=True" 
              timeout="20" />
```

### Authentication

```xml
<system.web>
  <authentication mode="Forms">
    <forms loginUrl="~/Account/Login" 
           timeout="2880" 
           slidingExpiration="true" />
  </authentication>
  <authorization>
    <deny users="?" />
  </authorization>
</system.web>
```

**Note**: Current implementation doesn't include authentication. This is a placeholder for future enhancement.

## Entity Framework Configuration

```xml
<entityFramework>
  <defaultConnectionFactory type="System.Data.Entity.Infrastructure.LocalDbConnectionFactory, EntityFramework">
    <parameters>
      <parameter value="mssqllocaldb" />
    </parameters>
  </defaultConnectionFactory>
  <providers>
    <provider invariantName="System.Data.SqlClient" 
              type="System.Data.Entity.SqlServer.SqlProviderServices, EntityFramework.SqlServer" />
  </providers>
</entityFramework>
```

**For Production**: Update to use SQL Server connection factory

```xml
<entityFramework>
  <defaultConnectionFactory type="System.Data.Entity.Infrastructure.SqlConnectionFactory, EntityFramework">
    <parameters>
      <parameter value="Data Source=PROD_SERVER;Integrated Security=True;MultipleActiveResultSets=True" />
    </parameters>
  </defaultConnectionFactory>
</entityFramework>
```

## IIS Configuration

### Application Pool Settings

**Recommended Settings**:
- **.NET CLR Version**: v4.0
- **Managed Pipeline Mode**: Integrated
- **Identity**: ApplicationPoolIdentity (or domain account)
- **Start Mode**: AlwaysRunning (for production)
- **Idle Timeout**: 20 minutes (default) or 0 (never timeout)

**PowerShell Configuration**:
```powershell
Import-Module WebAdministration

# Create application pool
New-WebAppPool -Name "LoanProcessingAppPool"

# Configure settings
Set-ItemProperty IIS:\AppPools\LoanProcessingAppPool -Name managedRuntimeVersion -Value "v4.0"
Set-ItemProperty IIS:\AppPools\LoanProcessingAppPool -Name managedPipelineMode -Value "Integrated"
Set-ItemProperty IIS:\AppPools\LoanProcessingAppPool -Name startMode -Value "AlwaysRunning"
Set-ItemProperty IIS:\AppPools\LoanProcessingAppPool -Name processModel.idleTimeout -Value "00:00:00"

# Set recycling
Set-ItemProperty IIS:\AppPools\LoanProcessingAppPool -Name recycling.periodicRestart.time -Value "1.05:00:00"
```

### Website Bindings

```powershell
# HTTP binding
New-WebBinding -Name "LoanProcessing" -Protocol "http" -Port 80 -HostHeader "loanprocessing.company.com"

# HTTPS binding
New-WebBinding -Name "LoanProcessing" -Protocol "https" -Port 443 -HostHeader "loanprocessing.company.com"
```


## Environment-Specific Configuration

### Using Web.config Transformations

**Web.Release.config Example**:
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  
  <!-- Replace connection string -->
  <connectionStrings>
    <add name="LoanProcessingConnection" 
         connectionString="Server=PROD_SERVER;Database=LoanProcessing;Trusted_Connection=True;Encrypt=True" 
         xdt:Transform="SetAttributes" 
         xdt:Locator="Match(name)"/>
  </connectionStrings>
  
  <!-- Update app settings -->
  <appSettings>
    <add key="EnableDetailedLogging" value="false" 
         xdt:Transform="SetAttributes" 
         xdt:Locator="Match(key)"/>
  </appSettings>
  
  <!-- Disable debug mode -->
  <system.web>
    <compilation xdt:Transform="RemoveAttributes(debug)" />
    <customErrors mode="On" xdt:Transform="Replace" />
  </system.web>
  
</configuration>
```

### Using Environment Variables

**Read from Environment Variables**:
```csharp
// In Global.asax.cs or startup code
public class MvcApplication : System.Web.HttpApplication
{
    protected void Application_Start()
    {
        // Override connection string from environment variable
        var envConnectionString = Environment.GetEnvironmentVariable("LOANPROCESSING_CONNECTION_STRING");
        if (!string.IsNullOrEmpty(envConnectionString))
        {
            var config = WebConfigurationManager.OpenWebConfiguration("~");
            var connectionStrings = config.ConnectionStrings.ConnectionStrings;
            connectionStrings["LoanProcessingConnection"].ConnectionString = envConnectionString;
            config.Save();
        }
    }
}
```

**Set Environment Variables**:
```powershell
# System-wide
[Environment]::SetEnvironmentVariable("LOANPROCESSING_CONNECTION_STRING", "Server=PROD;Database=LoanProcessing;Trusted_Connection=True", "Machine")

# User-specific
[Environment]::SetEnvironmentVariable("LOANPROCESSING_CONNECTION_STRING", "Server=PROD;Database=LoanProcessing;Trusted_Connection=True", "User")

# Process-specific (IIS Application Pool)
Set-ItemProperty IIS:\AppPools\LoanProcessingAppPool -Name environmentVariables -Value @{
    LOANPROCESSING_CONNECTION_STRING="Server=PROD;Database=LoanProcessing;Trusted_Connection=True"
}
```

## Security Configuration

### Encrypt Sensitive Sections

```powershell
# Navigate to application directory
cd C:\inetpub\wwwroot\LoanProcessing

# Encrypt connection strings
aspnet_regiis -pef "connectionStrings" . -prov "RsaProtectedConfigurationProvider"

# Encrypt app settings
aspnet_regiis -pef "appSettings" . -prov "RsaProtectedConfigurationProvider"

# Verify encryption
Get-Content Web.config | Select-String -Pattern "EncryptedData"
```

**Result**: Sections are encrypted but automatically decrypted by ASP.NET at runtime.

### SSL/TLS Configuration

**Require HTTPS**:
```xml
<system.webServer>
  <rewrite>
    <rules>
      <rule name="Redirect to HTTPS" stopProcessing="true">
        <match url="(.*)" />
        <conditions>
          <add input="{HTTPS}" pattern="off" ignoreCase="true" />
        </conditions>
        <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
      </rule>
    </rules>
  </rewrite>
</system.webServer>
```

**Or in Global.asax.cs**:
```csharp
protected void Application_BeginRequest(object sender, EventArgs e)
{
    if (!Request.IsSecureConnection && !Request.IsLocal)
    {
        Response.Redirect("https://" + Request.ServerVariables["HTTP_HOST"] + Request.RawUrl);
    }
}
```

### Security Headers

```xml
<system.webServer>
  <httpProtocol>
    <customHeaders>
      <add name="X-Frame-Options" value="SAMEORIGIN" />
      <add name="X-Content-Type-Options" value="nosniff" />
      <add name="X-XSS-Protection" value="1; mode=block" />
      <add name="Referrer-Policy" value="strict-origin-when-cross-origin" />
      <add name="Content-Security-Policy" value="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" />
    </customHeaders>
  </httpProtocol>
</system.webServer>
```


## Performance Configuration

### Output Caching

```xml
<system.web>
  <caching>
    <outputCacheSettings>
      <outputCacheProfiles>
        <add name="StaticContent" duration="3600" varyByParam="none" />
        <add name="CustomerList" duration="300" varyByParam="*" />
        <add name="Reports" duration="600" varyByParam="*" />
      </outputCacheProfiles>
    </outputCacheSettings>
  </caching>
</system.web>
```

**Usage in Controllers**:
```csharp
[OutputCache(CacheProfile = "CustomerList")]
public ActionResult Index()
{
    // ...
}
```

### Compression

```xml
<system.webServer>
  <urlCompression doStaticCompression="true" doDynamicCompression="true" />
  <httpCompression>
    <dynamicTypes>
      <add mimeType="text/*" enabled="true" />
      <add mimeType="application/json" enabled="true" />
      <add mimeType="application/javascript" enabled="true" />
    </dynamicTypes>
    <staticTypes>
      <add mimeType="text/*" enabled="true" />
      <add mimeType="application/javascript" enabled="true" />
      <add mimeType="application/json" enabled="true" />
    </staticTypes>
  </httpCompression>
</system.webServer>
```

### Static Content Caching

```xml
<system.webServer>
  <staticContent>
    <clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="7.00:00:00" />
  </staticContent>
</system.webServer>
```

## Logging Configuration

### Application Insights (Azure)

```xml
<appSettings>
  <add key="ApplicationInsights:InstrumentationKey" value="YOUR_INSTRUMENTATION_KEY" />
</appSettings>
```

### Custom Logging

**Add to Web.config**:
```xml
<appSettings>
  <add key="LogPath" value="C:\Logs\LoanProcessing" />
  <add key="LogLevel" value="Information" />
  <add key="EnableFileLogging" value="true" />
  <add key="EnableEventLogLogging" value="true" />
</appSettings>
```

**Implement Logger**:
```csharp
public class Logger
{
    private static readonly string LogPath = ConfigurationManager.AppSettings["LogPath"];
    private static readonly string LogLevel = ConfigurationManager.AppSettings["LogLevel"];
    
    public static void LogError(string message, Exception ex = null)
    {
        var logMessage = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} [ERROR] {message}";
        if (ex != null)
        {
            logMessage += $"\nException: {ex.Message}\nStackTrace: {ex.StackTrace}";
        }
        
        File.AppendAllText(Path.Combine(LogPath, $"error_{DateTime.Now:yyyyMMdd}.log"), logMessage + "\n");
    }
    
    public static void LogInfo(string message)
    {
        if (LogLevel == "Information" || LogLevel == "Debug")
        {
            var logMessage = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} [INFO] {message}";
            File.AppendAllText(Path.Combine(LogPath, $"info_{DateTime.Now:yyyyMMdd}.log"), logMessage + "\n");
        }
    }
}
```

## Configuration Best Practices

### 1. Never Store Secrets in Source Control

**Bad**:
```xml
<add key="ApiKey" value="secret123" />
```

**Good**:
```xml
<add key="ApiKey" value="" />
<!-- Set via environment variable or Azure Key Vault -->
```

### 2. Use Configuration Transformations

- `Web.config`: Base configuration
- `Web.Debug.config`: Development overrides
- `Web.Release.config`: Production overrides

### 3. Validate Configuration on Startup

```csharp
protected void Application_Start()
{
    ValidateConfiguration();
    // ... other startup code
}

private void ValidateConfiguration()
{
    var connectionString = ConfigurationManager.ConnectionStrings["LoanProcessingConnection"];
    if (connectionString == null || string.IsNullOrEmpty(connectionString.ConnectionString))
    {
        throw new ConfigurationErrorsException("LoanProcessingConnection not configured");
    }
    
    // Test database connection
    try
    {
        using (var conn = new SqlConnection(connectionString.ConnectionString))
        {
            conn.Open();
        }
    }
    catch (Exception ex)
    {
        throw new ConfigurationErrorsException("Cannot connect to database", ex);
    }
}
```

### 4. Document All Settings

Maintain a configuration documentation file listing:
- Setting name
- Purpose
- Valid values
- Default value
- Environment-specific values

### 5. Use Strongly-Typed Configuration

```csharp
public class AppSettings
{
    public static int MaxLoanAmountPersonal => 
        int.Parse(ConfigurationManager.AppSettings["MaxLoanAmount_Personal"]);
    
    public static int MaxLoanAmountAuto => 
        int.Parse(ConfigurationManager.AppSettings["MaxLoanAmount_Auto"]);
    
    public static int MinCreditScore => 
        int.Parse(ConfigurationManager.AppSettings["MinCreditScore"]);
}

// Usage
if (creditScore < AppSettings.MinCreditScore)
{
    // ...
}
```

## Troubleshooting Configuration Issues

### Issue: "Configuration system failed to initialize"

**Cause**: Malformed XML in Web.config

**Solution**:
1. Validate XML syntax
2. Check for unclosed tags
3. Verify attribute quotes
4. Use XML validator tool

### Issue: "Connection string not found"

**Cause**: Incorrect connection string name

**Solution**:
```csharp
// Check available connection strings
foreach (ConnectionStringSettings cs in ConfigurationManager.ConnectionStrings)
{
    Console.WriteLine($"Name: {cs.Name}, Provider: {cs.ProviderName}");
}
```

### Issue: "Configuration changes not taking effect"

**Cause**: Application not restarted or caching

**Solution**:
1. Recycle application pool
2. Touch Web.config to force restart
3. Clear browser cache
4. Check for output caching

## Next Steps

After configuring the application:

1. **Test Configuration**: Verify all settings work correctly
2. **Security Review**: Ensure no secrets in plain text
3. **Performance Testing**: Validate caching and compression
4. **Monitoring Setup**: Configure logging and alerts
5. **Documentation**: Update configuration documentation

## Additional Resources

- **ASP.NET Configuration**: https://docs.microsoft.com/en-us/aspnet/web-forms/overview/deployment/
- **Web.config Transformations**: https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/transform-webconfig
- **IIS Configuration**: https://docs.microsoft.com/en-us/iis/configuration/
- **Security Best Practices**: https://docs.microsoft.com/en-us/aspnet/web-forms/overview/security/

---

**Last Updated**: 2024  
**Application Version**: 1.0.0  
**.NET Framework**: 4.7.2

