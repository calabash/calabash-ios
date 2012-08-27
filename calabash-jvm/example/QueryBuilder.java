package calabash_jvm;
import calabash_jvm.API;
import java.util.*;

import static calabash_jvm.API.*;

public class QueryBuilder extends AbstractList
{

    private List list;

    public QueryBuilder()
    {
        this.list = new ArrayList(10);
    }

    public QueryBuilder(List l)
    {
        this.list = new ArrayList(l);
    }

    public Object get(int i) { return this.list.get(i);}
    public int size() {return this.list.size();}


    public QueryBuilder dup()
    {
        return new QueryBuilder(this.list);
    }

    public static QueryBuilder view(String s)
    {
        return new QueryBuilder().type(s);
    }

    public QueryBuilder type(String t)
    {
        this.list.add(t);
        return this;
    }

    public QueryBuilder parent()
    {
        this.list.add("parent");
        return this;
    }
    public QueryBuilder descendant()
    {
        this.list.add("descendant");
        return this;
    }

    public QueryBuilder child()
    {
        this.list.add("child");
        return this;
    }

    public QueryBuilder with(String key, Object val)
    {
        this.list.add(Collections.singletonMap(key,val));
        return this;
    }

    public QueryBuilder marked(String mark)
    {
        return with("marked",mark);
    }

    public QueryBuilder index(int i)
    {
        this.list.add(calabash_jvm.API.index(i));
        return this;
    }

    public QueryBuilder css(String s)
    {
        this.list.add(calabash_jvm.API.css(s));
        return this;
    }

    public QueryBuilder xpath(String xp)
    {
        this.list.add(calabash_jvm.API.xpath(xp));
        return this;
    }

    public List toQuery()
    {
        return Collections.unmodifiableList(this.list);
    }


}
