(ns ^{:doc "Contains methods to get device details and clean start the simulator."
      :author "Mayank Jain <mayank@helpshift.com>"}
  calabash-jvm.launcher
  (:require [me.raynes.conch :refer [programs with-programs let-programs]]
            [clojure.data.json :as json]))

;;; Required for fresh-start-simulator & getting device details.
(programs rm)
(programs ls)
(programs killall)
(programs mkdir)
(programs whoami)
(programs ios-sim)
(programs curl)

(defn substring?
  "Checks for substring returns boolean value,
  true if a substring."
  [sub string]
  (> (.indexOf string sub) -1))

(defn get-device-details-all
  "Returns a map of details"
  []
  (json/read-json (curl (str calabash-jvm.env/*endpoint* "/version"))))

(defn get-device-details-app-id
  "Returns app-id"
  []
  (:app_id (get-device-details-all)))

(defn get-device-details-app-name
  "Returns app-name"
  []
  (:app_name (get-device-details-all)))

(defn get-device-details-version
  "Returns iOS OS Version"
  []
  (:iOS_version (get-device-details-all)))

(defn get-device-details-family
  "Returns iphone or ipad"
  []
  (:simulator_device (get-device-details-all)))

(defn get-device-details-retina?
  "Retuns :
   Retina NA : If not retina.
   Retina 3.5
   Retina 4.0"
  []
  (let [retina (second (first (re-seq #"(Retina.*)\)/"
                                      (:simulator (get-device-details-all)))))]
    (if (nil? retina)
      "Retina NA"
      retina)))

(defn get-device-details-summary
  "Returns a summary of details."
  []
  (str (get-device-details-app-id) " "
       (get-device-details-app-name) " "
       (get-device-details-family) " "
       (get-device-details-version) " "
       (get-device-details-retina?)))

(defn get-user-path
  "Returns full path using current user."
  [path]
  (format path
          (first (whoami {:seq true}))))

(defn get-project-dir
  "Returns full path for given project directory."
  [project-name]
  (let [user-path (get-user-path "/Users/%s/Library/Developer/Xcode/DerivedData/")
        project-list (ls user-path {:seq true})]
    (str user-path
         (first (filter #(substring? project-name %) project-list))
         "/")))

(defn get-app-full-path
  "Example : (get-app-full-path \"QNote\" \"LeNote\")"
  [project-name app-name]
  (str (get-project-dir project-name) (format "Build/Products/Debug-iphonesimulator/%s.app" app-name)))

(defn fresh-start-simulator
  "Requires ios-sim installed : https://github.com/phonegap/ios-sim
   version : 5.0, 5.1, 6.0, 6.1
   family : ipad, iphone
   project-name : QNote
   app-name : LeNote
   extras (Optional) : --retina OR --retina --tall"
  [family version project-name app-name & extras]
  (killall "iPhone Simulator")
  (Thread/sleep 2000)
  (rm "-rf" (get-user-path "/Users/%s/Library/Application Support/iPhone Simulator/"))
  (Thread/sleep 2000)
  (apply ios-sim "launch" (get-app-full-path project-name app-name) "--sdk" version "--exit" "--family" family extras)
  (apply str "Fresh Simulator Started : " family " " version " " project-name " " app-name " " extras))
