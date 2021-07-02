# Metarouter Analytics

analytics-ios is an iOS client for Metarouter.

Special thanks to [Tony Xiao](https://github.com/tonyxiao), [Lee Hasiuk](https://github.com/lhasiuk) and [Cristian Bica](https://github.com/cristianbica) for their contributions to the library!

<div align="center">
  <img src="https://user-images.githubusercontent.com/1385202/73848360-a6a9d700-4830-11ea-929a-3394d4b0d2cf.png"/>
  <p><b><i>You can't fix what you can't measure</i></b></p>
</div>

Analytics helps you measure your users, product, and business. It unlocks insights into your app's funnel, core business metrics, and whether you have product-market fit.

## How to get started

[Metarouter](https://metarouter.io) collects analytics data and allows you to send it to more than 250 apps (such as Google Analytics, Mixpanel, Optimizely, Facebook Ads, Slack, Sentry) just by flipping a switch. You only need one Metarouter code snippet, and you can turn integrations on and off at will, with no additional code. [Sign up with Metarouter today](https://app.metarouter.io/signup).

### Why?
1. **Power all your analytics apps with the same data**. Instead of writing code to integrate all of your tools individually, send data to Metarouter, once.

2. **Install tracking for the last time**. We're the last integration you'll ever need to write. You only need to instrument Metarouter once. Reduce all of your tracking code and advertising tags into a single set of API calls.

3. **Send data from anywhere**. Send Metarouter data from any device, and we'll transform and send it on to any tool.

4. **Query your data in SQL**. Slice, dice, and analyze your data in detail with Metarouter SQL. We'll transform and load your customer behavioral data directly from your apps into Amazon Redshift, Google BigQuery, or Postgres. Save weeks of engineering time by not having to invent your own data warehouse and ETL pipeline.

    For example, you can capture data on any app:
    ```js
    analytics.track('Order Completed', { price: 99.84 })
    ```
    Then, query the resulting data in SQL:
    ```sql
    select * from app.order_completed
    order by price desc
    ```

## Installation

Analytics is available through [CocoaPods](http://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage).

### CocoaPods

```ruby
pod "MetarouterAnalytics", "3.7.0"
```
Note: Metarouter _strongly_ recommends that you use a dynamic framework to manage your project dependencies. If you prefer static libraries, you can add `use_modular_headers!` or `use_frameworks! :linkage => :static` in your Podfile. However, you must then _manually update_ all of your dependencies on a regular schedule.

### Carthage

```
github "super-collider/analytics-ios"
```

### Swift Package Manager (SPM)

To add analytics-ios via Swift Package Mangaer, it is possible to add it one of two ways:

#### Xcode
![Xcode Add SPM Package](https://user-images.githubusercontent.com/917994/119199146-69765200-ba3f-11eb-9173-93cfb5f3cabd.png)

![ChoosePackageRepository](https://user-images.githubusercontent.com/917994/119199143-68ddbb80-ba3f-11eb-9bf2-5dc11c208abd.png)

![ChoosePackageOptions](https://user-images.githubusercontent.com/917994/119199139-67ac8e80-ba3f-11eb-9941-fc541030f3df.png)


#### Package.swift
```
import PackageDescription

let package = Package(
    name: "MyApplication",
    dependencies: [
        // Add a package containing Analytics as the name along with the git url
        .package(
            name: "Metarouter",
            url: "git@github.com:super-collider/analytics-ios.git"
        )
    ],
    targets: [
        name: "MyApplication",
        dependencies: ["Metarouter"] // Add Analytics as a dependency of your application
    ]
)
```
Note: Metarouter recommends that you use Xcode to add your package.

## Quickstart

Refer to the Quickstart documentation at [https://docs.metarouter.io/docs/quick-start-guide](https://docs.metarouter.io/docs/quick-start-guide).

## Documentation

More detailed documentation is available at [https://docs.metarouter.io/docs/analyticsjs-for-ios](https://docs.metarouter.io/docs/analyticsjs-for-ios).
