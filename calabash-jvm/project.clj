(defproject calabash-jvm "0.0.1"
  :description "JVM client for calabash-ios-server for automated iOS functional testing"
  :repositories {"sonatype"
                 {:url "http://oss.sonatype.org/content/repositories/releases"
                  :snapshots false
                  :releases {:checksum :fail :update :always}}
                 "sonatype-snapshots"
                 {:url "http://oss.sonatype.org/content/repositories/snapshots"
                  :snapshots true
                  :releases {:checksum :fail :update :always}}}
  :dependencies [[org.clojure/clojure "1.4.0"]
                 [org.clojure/data.json "0.1.3"]
                 [clj-http "0.5.3"]
                 [org.slf4j/slf4j-log4j12 "1.6.4"]
                 [log4j "1.2.16" :exclusions [javax.mail/mail
                                              javax.jms/jms
                                              com.sun.jdmk/jmxtools
                                              com.sun.jmx/jmxri]]
;                 [info.cukes/cucumber-java "1.0.11"]
;                 [info.cukes/cucumber-junit "1.0.11"]
;                 [junit/junit "4.10"]
                 [org.clojure/tools.logging "0.2.3"]
                 [clj-logging-config/clj-logging-config "1.9.8"]]

  :plugins [[lein-swank "1.4.4"]]

  :resources-path "resources"
  :dev-dependencies [[clojure-source "1.4.0"]])
