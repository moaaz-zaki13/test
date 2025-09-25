module.exports = [
  {
    files: ["**/*.js"],

    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        node: true,
      },
    },

    rules: {
      "no-unused-vars": "warn",
      "no-console": "off",
    },
  },
];
