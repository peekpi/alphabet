package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
)

type input struct {
	in    []byte
	index int
}

func (in *input) skipWhitespace() {
	off := in.index
	for _, n := range in.in[off:] {
		if n == ' ' || n == '\t' || n == '\n' || n == '\r' {
			in.index++
			continue
		}
		return
	}
}

func isLitera(n byte) bool {
	return (n >= 'a' && n <= 'z') || (n >= 'A' && n <= 'Z') || (n >= '0' && n <= '9') || n == '_'
}

func (in *input) litera() string {
	off := in.index
	str := ""
	for _, n := range in.in[off:] {
		if isLitera(n) {
			str += string(n)
			in.index++
			continue
		}
		return str
	}
	return str
}

func (in *input) expect(ch byte) {
	if ch != in.in[in.index] {
		panic(ch)
	}
	in.index++
}

func (in *input) skipNote() {
	off := in.index
	for _, n := range in.in[off:] {
		if n == '\n' {
			return
		}
		in.index++
	}
}

func (in *input) next() string {
	for {
		in.skipWhitespace()
		ch := in.in[in.index]
		if ch == '/' {
			in.expect('/')
			in.expect('/')
			in.skipNote()
			continue
		}
		if isLitera(ch) {
			return in.litera()
		}
		if ch == '}' {
			return ""
		}
		in.index++
	}
}

func newInput(f string) *input {
	b, err := ioutil.ReadFile(f) // just pass the file name
	if err != nil {
		panic(err)
	}
	return &input{
		in: b,
	}
}

func (in *input) expectToken(str string) {
	if str != in.next() {
		panic(str)
	}
}

type solStruct struct {
	name string
	typ  []string
	size []int
	val  []string
}

func newSolStruct(in *input) *solStruct {
	sol := &solStruct{}
	in.expectToken("struct")
	sol.name = in.next()
	for {
		str := in.next()
		if str == "" {
			break
		}
		sol.typ = append(sol.typ, str)
		sol.val = append(sol.val, in.next())
		size, err := strconv.Atoi(string(str[4:]))
		if str == "address" {
			size = 160
			err = nil
		}
		if err != nil {
			panic(err)
		}
		sol.size = append(sol.size, size)
	}
	return sol
}

var enFuncFmt = "function %sEncode(%s memory s) internal pure returns(uint256) {return %s;}"

var deFuncFmt = "function %sDecode(uint256 en) internal pure returns(%s memory) {return %s(%s);}"

func (sol *solStruct) enStr() string {
	str := ""
	total := 0
	for i, size := range sol.size {
		if i > 0 {
			str += "|"
		}
		str += fmt.Sprintf("uint256(s.%s)", sol.val[i])
		if total > 0 {
			str += fmt.Sprintf("<<%d", total)
		}
		total += size
		if total > 256 {
			panic(total)
		}
	}
	return str
}

func (sol *solStruct) deStr() string {
	str := ""
	total := 0
	for i, size := range sol.size {
		if i > 0 {
			str += ","
		}
		if total > 0 {
			str += fmt.Sprintf("%s(en>>%d)", sol.typ[i], total)
		} else {
			str += fmt.Sprintf("%s(en)", sol.typ[i])
		}
		total += size
	}
	return str
}

func (sol *solStruct) serialization() string {
	str := fmt.Sprintf(enFuncFmt, sol.name, sol.name, sol.enStr())
	str += "\n"
	str += fmt.Sprintf(deFuncFmt, sol.name, sol.name, sol.name, sol.deStr())
	return str
}

func main() {
	in := newInput(os.Args[1])
	sol := newSolStruct(in)
	fmt.Println(sol.serialization())
}
