package com.sandinh.core;

class LambdaEx {
    /**
		Concatenate a list of lists.

		The order of elements is preserved.
	**/
	public static function flatten<A>( it : Iterable<Iterable<A>> ) : List<A> {
		var l = new List<A>();
		for (e in it)
			for (x in e)
				l.add(x);
		return l;
	}

	/**
		A composition of map and flatten.

		The order of elements is preserved.

		If `f` is null, the result is unspecified.
	**/
	public static function flatMap<A,B>( it : Iterable<A>, f: A -> Iterable<B> ) : List<B> {
		return flatten(Lambda.map(it, f));
	}

    /** Creates an Array from Iterator `it` */
    public static function array<A>( it : Iterator<A> ) : Array<A> {
        var a = new Array<A>();
        while(it.hasNext())
            a.push(it.next());
        return a;
    }

    /**
        Tells if `it` contains an element for which `f` is true.

        This function returns true as soon as an element is found for which a
        call to `f` returns true.

        If no such element is found, the result is false.

        If `f` is null, the result is unspecified.
    **/
    public static function exists<A>( it : Iterator<A>, f : A -> Bool ): Bool {
        while (it.hasNext())
            if (f(it.next()))
                return true;
        return false;
    }

    /**
        Returns the first element of `it` for which `f` is true.

        This function returns as soon as an element is found for which a call to
        `f` returns true.

        If no such element is found, the result is null.

        If `f` is null, the result is unspecified.
    **/
    public static function find<T>( it : Iterator<T>, f : T -> Bool ) : Null<T> {
        while (it.hasNext()) {
            var v = it.next();
            if(f(v)) return v;
        }
        return null;
    }
}
