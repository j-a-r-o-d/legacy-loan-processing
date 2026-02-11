# Security Policy

## Project Status

This is a **demonstration/educational project** designed to showcase legacy .NET Framework patterns and modernization opportunities. It is **not intended for production use**.

## Supported Versions

As this is a demo project, there are no officially supported versions. The codebase is provided as-is for educational purposes.

## Known Security Considerations

This application intentionally demonstrates legacy patterns that may have security implications:

1. **Legacy .NET Framework 4.7.2**: While still supported by Microsoft, newer frameworks have better security features
2. **Database-Centric Logic**: Business logic in stored procedures can be harder to audit
3. **Limited Input Validation**: Demonstrates basic validation patterns typical of legacy applications
4. **No Authentication/Authorization**: This demo does not implement user authentication
5. **SQL Injection Protection**: Uses parameterized queries, but review before any production use
6. **Error Handling**: Displays detailed errors in development mode

## Security Best Practices for Production Use

If you adapt this code for production, consider:

- Implement proper authentication and authorization (ASP.NET Identity, OAuth, etc.)
- Add comprehensive input validation and sanitization
- Enable HTTPS/TLS encryption
- Implement rate limiting and CSRF protection
- Use secure connection string storage (Azure Key Vault, AWS Secrets Manager, etc.)
- Enable security headers (HSTS, CSP, X-Frame-Options, etc.)
- Implement proper logging and monitoring
- Regular security audits and dependency updates
- Follow OWASP Top 10 guidelines

## Reporting a Vulnerability

While this is a demo project, if you discover a security vulnerability that could affect users who might adapt this code:

1. **Do Not** open a public issue
2. Email the repository maintainer with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

We will acknowledge receipt within 48 hours and provide a timeline for addressing the issue.

## Disclaimer

This software is provided for educational purposes only. The authors and contributors are not responsible for any security issues that arise from using this code in production environments. Always conduct thorough security reviews and testing before deploying any application to production.

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Microsoft Security Best Practices](https://docs.microsoft.com/en-us/aspnet/core/security/)
- [.NET Security Guidelines](https://docs.microsoft.com/en-us/dotnet/standard/security/)
