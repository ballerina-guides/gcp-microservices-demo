const CurrencyOption = (props) => {
  return (
    <option value={props.user_currency} selected="selected">{props.user_currency}</option>
  );
};

export default CurrencyOption;
