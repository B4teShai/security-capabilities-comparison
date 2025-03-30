# Visualizations for Academic Paper

## Figure 1: Security Capabilities Radar Chart

```
                Input Validation
                      ▲
                      │
                   5  │
                      │
    Error Handling    │    XSS Protection
                  4  ┌┼┐
                     │ │
                  3  │ │
                     │ │                  Legend:
Dependency Security 2 │ │  JWT Security   ―――― Java
                     │ │                  ····· TypeScript
                  1  │ │                  ---- Golang
                     │ │
                  0  └┴┘
                      │
                      │
          Cookie Security    CSRF Protection
```

## Figure 2: Security Implementation Effort (Lines of Code)

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Java        █████████████████████                      │
│              126 Lines                                  │
│                                                         │
│  TypeScript  █████████████████████████████              │
│              164 Lines                                  │
│                                                         │
│  Golang      ██████████████████████████████████████████ │
│              315 Lines                                  │
│                                                         │
│  0         100         200         300         400      │
└─────────────────────────────────────────────────────────┘
```

## Figure 3: Vulnerability Management Maturity

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Java             ████████████████████████████████ 95%  │
│                                                         │
│  TypeScript       ████████████████████████████     85%  │
│                                                         │
│  Golang           ███████████████████              60%  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Figure 4: Security Paradigm Comparison

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│               Default Security       Manual Config      │
│               ◄───────────────────────────────────────► │
│ High  │                                                 │
│       │       Java •                                    │
│       │                                                 │
│       │              TypeScript •                       │
│       │                                                 │
│       │                              Golang •           │
│ Low   │                                                 │
└─────────────────────────────────────────────────────────┘
```

## Figure 5: Security Maturity Model

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Level 5 │                                     Java     │
│  Industry Leading                                       │
│                                                         │
│  Level 4 │                         TypeScript           │
│  Comprehensive                                          │
│                                                         │
│  Level 3 │                 Golang                       │
│  Established                                            │
│                                                         │
│  Level 2 │                                              │
│  Emerging                                               │
│                                                         │
│  Level 1 │                                              │
│  Basic                                                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Table 1: Detailed Security Comparison

| Security Feature | Golang | TypeScript | Java |
|------------------|--------|------------|------|
| **Input Validation** | Manual in handlers | Zod schema validation | Bean Validation |
| **SQL Injection** | Parameterized queries | ORM + prepared statements | JPA/Hibernate |
| **XSS Protection** | No built-in protection | Content-Type headers | Spring Security |
| **CSRF Protection** | Custom implementation | csurf middleware | Built-in Spring Security |
| **Security Headers** | Manual configuration | Helmet.js | Spring Security defaults |
| **Rate Limiting** | Custom implementation | express-rate-limit | Spring Security |
| **Error Handling** | Custom handlers | Express middleware | ControllerAdvice |
| **Authentication** | Manual JWT handling | passport.js | Spring Security |

## Figure 6: Vulnerable Code by Language (per 1000 LOC)

```
┌─────────────────────────────────────────────────────────┐
│                           █                             │
│                       █   █                             │
│                       █   █                             │
│                       █   █        █                    │
│                   █   █   █    █   █                    │
│                   █   █   █    █   █   █                │
│                   █   █   █    █   █   █                │
│               █   █   █   █    █   █   █   █            │
│             ┌─────┬─────┬─────┬─────┬─────┬─────┐      │
│             │ XSS │CSRF │Input│Head.│Cook.│Rate │      │
│             └─────┴─────┴─────┴─────┴─────┴─────┘      │
│               Golang   TypeScript   Java                │
└─────────────────────────────────────────────────────────┘
```

## Figure 7: Security-Related Code Distribution in Each Implementation

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Java        ███████|███|██|██|█                        │
│              Framework | Config | Custom                │
│                                                         │
│  TypeScript  ████|██████|████                           │
│              Framework | Config | Custom                │
│                                                         │
│  Golang      ██|██████|████████████                     │
│              Framework | Config | Custom                │
│                                                         │
└─────────────────────────────────────────────────────────┘
``` 