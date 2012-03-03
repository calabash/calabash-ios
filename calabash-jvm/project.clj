(defproject calabash-jvm "1.0.0-SNAPSHOT"
  :description "JVM client for calabash-ios-server for automated iOS functional testing"
  :dependencies [[org.clojure/clojure "1.3.0"]
                 [org.clojure/data.json "0.1.1"]
                 [http.async.client "0.4.0"]
                 [org.slf4j/slf4j-log4j12 "1.6.4"]
                 [log4j "1.2.16" :exclusions [javax.mail/mail
                                              javax.jms/jms
                                              com.sun.jdmk/jmxtools
                                              com.sun.jmx/jmxri]]
                 [org.clojure/tools.logging "0.2.3"]
                 [clj-logging-config/clj-logging-config "1.9.6"]]
  :dev-dependencies [[clojure-source "1.3.0"]])
