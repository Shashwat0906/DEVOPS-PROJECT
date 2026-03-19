import js from "@eslint/js";
import globals from "globals";
import pluginReact from "eslint-plugin-react";
import pluginPrettier from "eslint-plugin-prettier";

export default [
  {
    files: ["**/*.{js,mjs,cjs,jsx}"],

    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },

    plugins: {
      js,
      react: pluginReact,
      prettier: pluginPrettier,
    },

    rules: {
      ...js.configs.recommended.rules,
      ...pluginReact.configs.recommended.rules,

      // React specific fixes
      "react/react-in-jsx-scope": "off", // React 17+
      "react/prop-types": "off",

      // Prettier integration
      "prettier/prettier": "error",
    },

    settings: {
      react: {
        version: "detect",
      },
    },
  },
];