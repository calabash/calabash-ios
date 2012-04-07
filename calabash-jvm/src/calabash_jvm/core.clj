(ns calabash-jvm.core
  (:require [http.async.client :as http]
            [clojure.data.json :as json]
            [clojure.tools.logging :as lg]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm.env :as env]))



;; The key is to start swank from emacs as the inferior lisp process instead of calling lein swank from the shell. One way to do this is to use elein (the command is M-x elein-swank). Then you can either inspect the output in the inferior lisp buffer (which is called *elein-swank* in the example of using elein), or execute slime-redirect-inferior-output and have the output inline in the repl. Clojure.contrib.logging is a useful tool for sending log output.
