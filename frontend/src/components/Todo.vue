<template>
  <header class="header">
    <h1>todos</h1>
    <input
      class="new-todo"
      autofocus
      autocomplete="off"
      placeholder="What need to be done?"
      v-model="newTodo"
      @keypress.enter="addTodo"
    />
  </header>
  <section class="main" v-show="todos.length" v-cloak>
    <ul class="todo-list">
      <li
        v-for="todo in todos"
        class="todo"
        :key="todo.id"
      >
      <div class="view">
        <label >{{ todo.title }}</label>
        <button class="destroy" @click="removeTodo(todo)"></button>
      </div>
      </li>
    </ul>
  </section>
</template>

<script>
import { defineComponent } from "vue";
import  axios  from "axios";

let baseURL = import.meta.env.VITE_API_ENDPOINT;
console.log(baseURL)
const headers = {"accept": "application/json", "x-token": "fake-super-secret-token"};

export default defineComponent({
  name: 'Todo',
  data() {
    return {
      todos: [],
      newTodo: '',
    }
  },
  mounted: function() {
    self = this
    axios({
      method: "GET",
      baseURL: baseURL,
      headers: headers,
      url: "/",
      validateStatus: function (status) {
        return status < 500;
      },
    }).then(function (response) {
      if (response.status < 400) {
        self.todos = response.data
      }
    }).catch(function (e){
      alert(e)
    });
  },
  methods: {
    addTodo: async function () {
      self = this
      const value = self.newTodo && self.newTodo.trim();
      if (!value) {
        return;
      }
      try {
        let response = await axios({
          method: "POST",
          baseURL: baseURL,
          headers: headers,
          url: "/",
          data: {title: value,completed: false},
        });
        self.todos.push(response.data);
        self.newTodo = "";
      } catch (e) {
        alert(e);
      }
    },
    removeTodo: async function(todo) {
      try {
        await axios({
          method: "DELETE",
          baseURL: baseURL,
          headers: headers,
          url: "/" + todo.id,
        });
        this.todos.splice(this.todos.indexOf(todo), 1);
      } catch (e) {
        alert(e)
      }
    },
  },
});
</script>
