--Highland Tactical Magic
local s,id=GetID()
function s.initial_effect(c)
	--1턴 1장 제한
	c:SetUniqueOnField(1,0,id)

	--효과: 6가지 중 2개 선택
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON+CATEGORY_DRAW+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={0x755}

--덱/패 카드명이 모두 다른지 체크
function s.deckhand_allunique(tp)
	local dg=Duel.GetFieldGroup(tp,LOCATION_DECK,0)
	local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	for dc in aux.Next(dg) do
		if hg:IsExists(Card.IsCode,1,nil,dc:GetCode()) then
			return false
		end
	end
	return true
end

--조건
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return s.deckhand_allunique(tp)
end

--대상
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

--효과 실행
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ops,opval = {},{}
	local c=e:GetHandler()
	
	--1 상대 필드 카드 1장 파괴
	table.insert(ops,aux.Stringid(id,1))
	table.insert(opval,1)
	--2 자신 필드 하이랜드 몬스터 공격력 +600
	table.insert(ops,aux.Stringid(id,2))
	table.insert(opval,2)
	--3 묘지 하이랜드 몬스터 특수 소환
	table.insert(ops,aux.Stringid(id,3))
	table.insert(opval,3)
	--4 덱에서 1장 드로우
	table.insert(ops,aux.Stringid(id,4))
	table.insert(opval,4)
	--5 LP 1500 회복
	table.insert(ops,aux.Stringid(id,5))
	table.insert(opval,5)
	--6 상대 필드 몬스터 1장 효과 무효 + ATK/DEF 0
	table.insert(ops,aux.Stringid(id,6))
	table.insert(opval,6)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
	local sel1=Duel.SelectOption(tp,table.unpack(ops))
	-- 첫 선택 제거 후 두번째 선택
	local ops2,opval2 = {},{}
	for i,v in ipairs(ops) do
		if i~=sel1+1 then
			table.insert(ops2,v)
			table.insert(opval2,opval[i])
		end
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
	local sel2=Duel.SelectOption(tp,table.unpack(ops2))
	local choice1=opval[sel1+1]
	local choice2=opval2[sel2+1]
	local choices={choice1,choice2}

	for _,choice in ipairs(choices) do
		if choice==1 then
			-- 상대 필드 카드 1장 파괴
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
			if #g>0 then Duel.Destroy(g,REASON_EFFECT) end
		elseif choice==2 then
			-- 자신 필드 하이랜드 몬스터 공격력 +600
			local g=Duel.GetMatchingGroup(function(tc) return tc:IsSetCard(0x755) end,tp,LOCATION_MZONE,0,nil)
			for tc in aux.Next(g) do
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_ATTACK)
				e1:SetValue(600)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
			end
		elseif choice==3 then
			-- 묘지 하이랜드 몬스터 특수 소환
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
				local g=Duel.SelectMatchingCard(tp,function(tc) return tc:IsSetCard(0x755) and tc:IsType(TYPE_MONSTER) end,tp,LOCATION_GRAVE,0,1,1,nil)
				if #g>0 then Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP) end
			end
		elseif choice==4 then
			-- 덱에서 1장 드로우
			Duel.Draw(tp,1,REASON_EFFECT)
		elseif choice==5 then
			-- LP 1500 회복
			Duel.Recover(tp,1500,REASON_EFFECT)
		elseif choice==6 then
			-- 상대 필드 몬스터 1장 효과 무효 + ATK/DEF 0
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
			local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
			if #g>0 then
				local tc=g:GetFirst()
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
				local e2=e1:Clone()
				e2:SetCode(EFFECT_SET_ATTACK_FINAL)
				e2:SetValue(0)
				tc:RegisterEffect(e2)
				local e3=e2:Clone()
				e3:SetCode(EFFECT_SET_DEFENSE_FINAL)
				tc:RegisterEffect(e3)
			end
		end
	end
end
