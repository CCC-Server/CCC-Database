--灰滅せし都の呪術師
--Shaman of the Ashened City
--scripted by 유희왕 덱 제작기

local s,id=GetID()
function s.initial_effect(c)
	-------------------------------------
	-- 특수 소환: "옵시딤"이 필드존에 있을 경우 핸드에서 특수 소환
	-------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-------------------------------------
	-- 일반 소환/특수 소환 성공 시: 덱에서 회멸 지속 마법/함정 세트
	-------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND) -- UI 용도, 유사한 카테고리 사용
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

------------------------------------------------------
-- 특수 소환 조건: 필드존에 "회멸의 도시 옵시딤"이 앞면 존재할 경우
------------------------------------------------------
function s.spcon(e,c)
	if c==nil then return true end
	return Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CARD_OBSIDIM_ASHENED_CITY),
			c:GetControler(),LOCATION_FZONE,LOCATION_FZONE,1,nil)
end

------------------------------------------------------
-- 덱에서 세트할 대상: 회멸 지속 마법/함정
------------------------------------------------------
function s.setfilter(c)
	return c:IsSetCard(SET_ASHENED)
		and c:IsType(TYPE_CONTINUOUS) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and not c:IsForbidden()
end

------------------------------------------------------
-- 효과 발동 타겟
------------------------------------------------------
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end

------------------------------------------------------
-- 효과 실행: 카드 1장을 고르고 앞면 세트
------------------------------------------------------
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end
