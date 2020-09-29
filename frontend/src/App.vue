<template>
  <Todo/>
</template>

<script>
import { defineComponent } from 'vue';
import Todo from './components/Todo.vue';

export default defineComponent({
  name: 'App',
  components: {
    Todo,
  }
});
</script>

<style>
</style>
