local s,id=GetID()
function s.initial_effect(c)
	-- ① 효과: 패 공개 → 캐터펄트 필드에 놓기
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON) -- 실제로는 MoveToField
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.catg)
	e1:SetOperation(s.caop)
	c:RegisterEffect(e1)

	-- ② 효과: 엑스트라 덱 특수 소환 시, 장착
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE+LOCATION_HAND+LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.eqcon)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)
end

-- 카드명 고정: "네메시스 아티팩트 캐터펄트"
local CATTERPULT_CODE = 128770328 -- 실제 카드 코드로 바꾸세요

-- ① 효과: 대상 없음
function s.catg(e,tp,eg,ep,ev,re,r,rp,chk)
	return true
end

-- ① 작동: 캐터펄트 덱에서 가져와서 필드에 놓기
function s.caop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.ConfirmCards(1-tp,c)
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2)) -- "캐터펄트를 선택하세요"
	local g=Duel.SelectMatchingCard(tp,function(c) return c:IsCode(CATTERPULT_CODE) end,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end

-- ② 효과 조건: 엑스트라 덱에서 네메시스 아티팩트 몬스터가 특수 소환
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c)
		return c:IsSetCard(0x764) and c:IsSummonPlayer(tp) and c:IsSummonLocation(LOCATION_EXTRA)
	end,1,nil)
end

-- 묘지 대상 필터
function s.eqfilter1(c)
	return c:IsSetCard(0x764) and c:IsType(TYPE_MONSTER)
end

-- 장착 대상 필터 (필드 위 몬스터)
function s.eqfilter2(c)
	return c:IsFaceup() and c:IsSetCard(0x764) and c:IsType(TYPE_MONSTER)
end

-- ② 타겟 지정
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.eqfilter1,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.eqfilter2,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g1=Duel.SelectMatchingCard(tp,s.eqfilter1,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetTargetCard(g1)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g2=Duel.SelectMatchingCard(tp,s.eqfilter2,tp,LOCATION_MZONE,0,1,1,nil)
	e:SetLabelObject(g2:GetFirst())
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g1,1,0,0)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget() -- 장착할 카드 (묘지에서)
	local c=e:GetHandler()		 -- 이 카드 (효과를 가진 카드)
	local ec=e:GetLabelObject()	-- 장착 대상 몬스터

	if not (tc and tc:IsRelateToEffect(e) and ec and ec:IsFaceup() and ec:IsControler(tp)) then return end

	if Duel.Equip(tp,tc,ec) then
		-- ① 장착 제한
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_OWNER_RELATE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(function(e,c) return e:GetOwner()==c end)
		tc:RegisterEffect(e1)

		-- ✅ ② 장착된 카드를 장착 마법으로 취급
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_CHANGE_TYPE)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		e2:SetValue(TYPE_SPELL+TYPE_EQUIP)
		tc:RegisterEffect(e2)

		-- ✅ ③ 효과 파괴 내성
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e3:SetRange(LOCATION_SZONE)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		e3:SetValue(1)
		tc:RegisterEffect(e3)

		-- 🔄 (선택) 전투 파괴 내성도 부여하고 싶을 경우
		--[[
		local e4=e3:Clone()
		e4:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		tc:RegisterEffect(e4)
		]]
	end
end
