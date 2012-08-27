package calabash_jvm;

import calabash_jvm.API;
import java.util.List;
import java.util.Map;
import calabash_jvm.QueryBuilder;


import static calabash_jvm.API.*;
import static calabash_jvm.QueryBuilder.view;

class Example
{

    public static void main(String[] args)
    {

        screenshot(null);
        touch(view("UITabBarButton").
              marked("Fourth"), null);


        QueryBuilder q = view("UIWebView");

        waitForExists(q,null);

        screenshot(null);

        scroll(q,"down");

        waitForExists(q.css("a"), null);

        touch(q, null);
        screenshot(null);

        System.exit(0);


    }
}
