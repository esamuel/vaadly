# Vaadly - Multi-Tenant Building Management App

Note: All references in this workspace assume the active project is vaadly.

A comprehensive **multi-tenant** building management solution built with Flutter, Firebase, and AI integration. Vaadly is designed for **Building Committees** to manage their buildings efficiently, while providing **App Owners** with centralized management capabilities.

## 🏢 **Multi-Tenant Architecture**

### **App Owner (You)**
- **Manages the entire Vaadly platform**
- **Onboards new building committees**
- **Provides app maintenance and updates**
- **Accesses system-wide analytics and management**
- **Manages global settings and configurations**

### **Building Committee (Your Customers)**
- **Manages their specific building(s)**
- **Accesses only their building's data**
- **Manages residents, units, and maintenance**
- **Handles financial operations for their building**
- **Uses AI-powered features for efficiency**

### **Residents (End Users)**
- **Access limited to their own unit data**
- **Submit maintenance requests**
- **View building announcements**
- **Access controlled by building committee**

## 🏗️ **Core Features**

### **For App Owners**
- **Multi-Building Dashboard**: Overview of all buildings in the system
- **Building Onboarding**: Add new buildings and committees
- **System Analytics**: Platform-wide performance metrics
- **App Management**: Updates, configurations, and maintenance
- **Revenue Tracking**: Subscription and usage analytics

### **For Building Committees**
- **Building Management**: Complete control over their building
- **Resident Management**: Add, edit, and manage residents
- **Unit Management**: Track all units and their status
- **Maintenance System**: AI-powered issue classification and resolution
- **Financial Management**: Track expenses, invoices, and payments
- **Voting System**: Democratic decision-making for building matters ([View Details](vote.md))
- **Communication**: Announcements and resident notifications

### **For Residents**
- **Personal Dashboard**: View their unit and personal information
- **Maintenance Requests**: Submit and track repair requests
- **Building Updates**: Receive announcements and notifications
- **Payment History**: View their financial records

## 🚀 **Tech Stack**

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Firestore (Multi-tenant database)
  - Cloud Functions (Serverless)
  - Storage (File Management)
  - Authentication (Multi-tenant)
  - Cloud Messaging (FCM)
- **AI**: OpenAI GPT-4
- **State Management**: Provider Pattern
- **Architecture**: Feature-based modular architecture with tenant isolation

## 📱 **App Structure**

```
lib/
├── core/                    # Core functionality
│   ├── models/             # Data models
│   │   ├── building.dart   # Building model
│   │   ├── unit.dart       # Unit model
│   │   └── resident.dart   # Resident model
│   ├── services/           # Business logic
│   │   ├── building_service.dart
│   │   ├── resident_service.dart
│   │   └── auth_service.dart
│   └── utils/              # Utilities
├── features/               # Feature modules
│   ├── dashboard/          # App owner dashboard
│   ├── building/           # Building management
│   ├── residents/          # Resident management
│   ├── maintenance/        # Maintenance system
│   ├── payments/           # Financial management
│   └── settings/           # App settings
└── main.dart              # App entry point
```

## 🗄️ **Multi-Tenant Database Schema**

### **Collections Structure**
```
app_owners/{ownerId}/           # App owner data
├── buildings/{buildingId}/     # Buildings owned by this app owner
│   ├── info/                  # Building information
│   ├── committee/             # Committee members
│   ├── units/{unitId}         # Building units
│   ├── residents/{residentId} # Building residents
│   ├── maintenance/{woId}     # Maintenance requests
│   ├── finances/{invoiceId}   # Financial records
│   └── settings/              # Building-specific settings
├── analytics/                 # Platform analytics
├── subscriptions/             # Building subscriptions
└── system_settings/           # Global app settings
```

### **Security Rules**
- **App Owner Access**: Full access to all buildings and system data
- **Building Committee Access**: Limited to their specific building
- **Resident Access**: Limited to their own unit and building announcements
- **Data Isolation**: Complete separation between different buildings
- **Role-based Permissions**: Hierarchical access control

## 📚 Firestore Spec (Windsurf-ready)

For the canonical Firestore collections, document schemas, roles/claims, security rules, Cloud Function, and required indexes, see:

- `docs/VAADLY_FIRESTORE_SPEC.md`

This spec is the source of truth for data access, auth, and backend enforcement.

## 🔄 **Workflow**

### **App Owner Workflow**
1. **Onboard New Building**: Add building and committee information
2. **Configure Building**: Set up building-specific settings and features
3. **Monitor Performance**: Track building usage and system health
4. **Provide Support**: Assist building committees with app usage
5. **System Updates**: Deploy new features and improvements

### **Building Committee Workflow**
1. **Building Setup**: Configure building details and units
2. **Resident Management**: Add and manage building residents
3. **Maintenance Management**: Handle repair requests and vendor coordination
4. **Financial Oversight**: Track expenses and manage building budget
5. **Communication**: Send announcements and updates to residents

### **Resident Workflow**
1. **Access Building**: Login with committee-provided credentials
2. **Submit Issues**: Report maintenance problems with photos
3. **Track Progress**: Monitor request status and updates
4. **Receive Updates**: Get building announcements and notifications

## 🤖 **AI Integration**

### **Multi-Tenant AI Features**
- **Building-Specific Learning**: AI adapts to each building's unique characteristics
- **Localized Classification**: Considers building type and location
- **Committee Preferences**: Learns from building committee decisions
- **Regional Optimization**: Adapts to local maintenance practices

### **AI-Powered Features**
- **Automatic Classification**: Categorizes issues by type and priority
- **Smart Vendor Assignment**: Recommends vendors based on building history
- **Predictive Maintenance**: Identifies potential issues before they occur
- **Cost Optimization**: Suggests cost-effective solutions

## 🔒 **Security & Privacy**

### **Multi-Tenant Security**
- **Complete Data Isolation**: No data leakage between buildings
- **Role-based Access Control**: Different permissions for different user types
- **Audit Logging**: Track all actions for security and compliance
- **Encrypted Storage**: Secure storage of sensitive information
- **Regular Security Updates**: Continuous security improvements

### **Compliance**
- **GDPR Compliance**: European data protection standards
- **Local Regulations**: Adherence to building management laws
- **Data Retention**: Configurable data retention policies
- **Privacy Controls**: Resident privacy protection features

## 📊 **Analytics & Reporting**

### **App Owner Analytics**
- **Platform Performance**: Overall system health and usage
- **Building Adoption**: Number of active buildings and users
- **Revenue Metrics**: Subscription and usage analytics
- **System Health**: Performance and reliability metrics

### **Building Committee Analytics**
- **Building Performance**: Maintenance efficiency and costs
- **Resident Satisfaction**: Issue resolution times and feedback
- **Financial Health**: Budget tracking and expense analysis
- **Vendor Performance**: Service quality and cost analysis

## 🚀 **Deployment & Scaling**

### **Multi-Tenant Deployment**
- **Horizontal Scaling**: Support for thousands of buildings
- **Regional Deployment**: Local data centers for compliance
- **Load Balancing**: Efficient resource distribution
- **Backup & Recovery**: Comprehensive data protection

### **Performance Optimization**
- **Tenant Isolation**: Efficient data separation and access
- **Caching Strategies**: Smart caching for improved performance
- **Offline Support**: Local data storage for reliability
- **Real-time Updates**: Live synchronization across all devices

## 🗺️ **Development Roadmap**

### **Phase 1: Foundation (Current)**
- ✅ Multi-tenant architecture design
- ✅ Building management system
- ✅ Resident management system
- ✅ Basic dashboard structure

### **Phase 2: Core Features**
- 🔄 Maintenance management system
- ✅ Financial management & pricing calculator
- 🔄 AI-powered features
- 🔄 Communication system

### **Phase 3: Advanced Features**
- 📋 **Voting System**: Democratic decision-making for building matters ([View Details](vote.md))
- 📋 Advanced analytics and reporting
- 📋 Mobile app optimization
- 📋 API integrations
- 📋 Advanced AI capabilities

### **Phase 4: Enterprise Features**
- 📋 Multi-building committee support
- 📋 Advanced security features
- 📋 Compliance and audit tools
- 📋 International expansion

## 💰 **Business Model**

### **Revenue Streams**
- **Building Subscriptions**: Monthly/annual fees per building
- **Feature Tiers**: Different pricing for different feature sets
- **Premium Support**: Enhanced support and training services
- **Custom Development**: Building-specific customizations

### **Pricing Strategy**
- **Starter Plan**: Basic building management features
- **Professional Plan**: Advanced features and AI capabilities
- **Enterprise Plan**: Custom solutions and dedicated support

## 🤝 **Support & Training**

### **For App Owners**
- **Technical Support**: Platform maintenance and troubleshooting
- **Business Consulting**: Growth and optimization strategies
- **Training Programs**: Committee onboarding and training
- **Marketing Support**: Building committee acquisition tools

### **For Building Committees**
- **User Training**: Comprehensive app usage training
- **Best Practices**: Building management optimization
- **Vendor Network**: Access to pre-vetted service providers
- **Community Support**: Peer learning and knowledge sharing

## 🌐 **Web Testing**

Test your Vaadly app on any device through a web browser! Perfect for development, testing, and demonstrations.

### **Quick Start**
```bash
# Build and serve web version
./scripts/serve_web.sh

# Or run in development mode with hot reload
./scripts/dev_web.sh
```

### **Access URLs**
- **Local Device**: http://localhost:8000
- **Network Devices**: http://192.168.1.130:8000 (your computer's IP)

### **Available Scripts**
- `./scripts/serve_web.sh` - Start production web server
- `./scripts/dev_web.sh` - Start development server with hot reload
- `./scripts/web_status.sh` - Check server status

### **Testing Features**
✅ **All app features work on web:**
- Building management and statistics
- Resident management with forms
- Maintenance system with vendor integration
- Responsive design for all screen sizes
- Hebrew text support
- Touch and mouse interactions

📚 **For detailed web testing instructions, see:** [WEB_TESTING.md](WEB_TESTING.md)

---

**Built with ❤️ for better building management across all communities**
