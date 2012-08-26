import calabash_jvm.API;
import java.util.List;
import java.util.Map;

class Example
{

    public static void main(String[] args)
    {
        List l = (List) API.queryq("[:UITableView]",null);
        System.err.println("-----");
        for (Object m : l)
            {
                System.err.println(m);
            }
    }
}
